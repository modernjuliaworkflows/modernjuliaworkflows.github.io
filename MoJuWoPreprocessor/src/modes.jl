# Fence execution: one sandbox module per page, four REPL modes plus plain
# `!` blocks, rendered as the REPL would show them.

const HIDEALL_RE = r"^\s*#\s*hideall\s*$"i
const HIDE_RE = r"#\s*hide\s*$"i

struct FenceError
    label::String
    message::String
end

mutable struct PageContext
    mod::Module
    relpath::String
    pagedir::String
    errors::Vector{FenceError}
end

function make_sandbox(relpath::AbstractString)
    name = Symbol("MJW_", replace(first(splitext(relpath)), r"[^A-Za-z0-9]+" => "_"))
    # Evaluating a `module` expression (as SafeTestsets does) gives the sandbox
    # the standard `eval`/`include` definitions, which a raw `Module()` lacks.
    return Core.eval(
        Main, Expr(
            :module, true, name,
            Expr(:block, :(ans = nothing))
        )
    )::Module
end

# Pkg warns when its REPL mode is driven programmatically; drop that noise
# but let everything else (e.g. `@warn` in page code) through.
struct PkgWarningFilter <: Logging.AbstractLogger
    parent::Logging.AbstractLogger
end
Logging.min_enabled_level(l::PkgWarningFilter) = Logging.min_enabled_level(l.parent)
Logging.shouldlog(l::PkgWarningFilter, args...) = Logging.shouldlog(l.parent, args...)
Logging.catch_exceptions(l::PkgWarningFilter) = Logging.catch_exceptions(l.parent)
function Logging.handle_message(
        l::PkgWarningFilter, level, message, _module, group, id,
        file, line; kwargs...
    )
    occursin("intended for interactive use", string(message)) && return nothing
    return Logging.handle_message(
        l.parent, level, message, _module, group, id,
        file, line; kwargs...
    )
end

# Fence code can log an error without throwing one —
# Base does exactly that when a package extension fails to load —
# and IOCapture reports no error for those.
# Recording error-level log messages lets such fences fail the build
# like thrown errors do (and `allow-error` sanction them alike).
struct ErrorLogRecorder <: Logging.AbstractLogger
    parent::Logging.AbstractLogger
    messages::Vector{String}
end
Logging.min_enabled_level(l::ErrorLogRecorder) = Logging.min_enabled_level(l.parent)
Logging.shouldlog(l::ErrorLogRecorder, args...) = Logging.shouldlog(l.parent, args...)
Logging.catch_exceptions(l::ErrorLogRecorder) = Logging.catch_exceptions(l.parent)
function Logging.handle_message(
        l::ErrorLogRecorder, level, message, _module, group, id,
        file, line; kwargs...
    )
    level >= Logging.Error && push!(l.messages, string(message))
    return Logging.handle_message(
        l.parent, level, message, _module, group, id,
        file, line; kwargs...
    )
end

# IOCapture merges stdout/stderr and installs a ConsoleLogger on the captured
# stream; io_context forces :color so the output carries ANSI codes even in
# non-interactive builds.
function capture(f)
    logged = String[]
    c = IOCapture.capture(;
        rethrow = InterruptException, color = true,
        io_context = [:color => true]
    ) do
        with_logger(ErrorLogRecorder(PkgWarningFilter(current_logger()), logged)) do
            f()
        end
    end
    return (; c.value, c.output, c.error, c.backtrace, logged_errors = logged)
end

# The context the REPL displays results with: truncated arrays, unqualified
# names for things defined in the page's own module.
displayctx(io::IO, mod::Module) =
    IOContext(io, :color => true, :limit => true, :displaysize => (24, 80), :module => mod)

unwrap_load_error(err) = err isa LoadError ? err.error : err

# REPL-style error line, without the (path-dependent) stacktrace.
function print_repl_error(io::IO, err, mod::Module)
    ctx = displayctx(io, mod)
    printstyled(ctx, "ERROR: "; color = Base.error_color(), bold = true)
    # `invokelatest` for the same reason as in `exec_julia`: the failing fence
    # may have just loaded the package that defines `showerror` for this error.
    Base.invokelatest(showerror, ctx, err)
    println(io)
    return nothing
end

function record_error!(ctx::PageContext, label::AbstractString, err)
    message = first(split(sprint((io, e) -> Base.invokelatest(showerror, io, e), err), '\n'))
    push!(ctx.errors, FenceError(String(label), message))
    return nothing
end

function record_logged_errors!(
        ctx::PageContext, label::AbstractString, messages::Vector{String}
    )
    for msg in messages
        message = string("error-level log: ", first(split(msg, '\n')))
        push!(ctx.errors, FenceError(String(label), message))
    end
    return nothing
end

# Captured output, normalized to end on a line boundary.
function print_captured(io::IO, output::AbstractString)
    isempty(output) && return nothing
    print(io, output)
    endswith(output, '\n') || println(io)
    return nothing
end

"""
    split_toplevel(code; filename) -> Vector{(source, exprs)}

Split fence code into REPL inputs: one per top-level expression, grouped by
starting line so `a = 1; b = 2` stays a single input, with the verbatim
source lines attached for the prompt echo.
"""
function split_toplevel(code::AbstractString; filename::AbstractString = "REPL")
    ex = Meta.parseall(String(code); filename = String(filename))
    if !(ex isa Expr && ex.head === :toplevel)
        return [(source = String(strip(code)), exprs = Any[ex])]
    end
    lines = split(code, '\n')
    starts = Int[]
    groups = Vector{Any}[]
    cur = 1
    for arg in ex.args
        if arg isa LineNumberNode
            cur = arg.line
        elseif !isempty(groups) && starts[end] == cur
            push!(groups[end], arg)
        else
            push!(starts, cur)
            push!(groups, Any[arg])
        end
    end
    out = @NamedTuple{source::String, exprs::Vector{Any}}[]
    for k in eachindex(groups)
        lo = starts[k]
        hi = k < lastindex(groups) ? starts[k + 1] - 1 : length(lines)
        seg = lines[lo:min(hi, length(lines))]
        while !isempty(seg) && isempty(strip(last(seg)))
            pop!(seg)
        end
        push!(out, (source = join(seg, '\n'), exprs = groups[k]))
    end
    return out
end

# `>` mode: echo and evaluate expression by expression; update `ans`; a
# trailing `;` or a `nothing` result suppresses the display, stdout does not.
function exec_julia(ctx::PageContext, code::AbstractString, label::AbstractString)
    io = IOBuffer()
    for (k, group) in enumerate(split_toplevel(code))
        k > 1 && println(io)
        print(io, julia_prompt(), group.source, '\n')
        suppress = REPL.ends_with_semicolon(group.source)
        for (j, ex) in enumerate(group.exprs)
            c = capture(() -> Core.eval(ctx.mod, ex))
            print_captured(io, c.output)
            record_logged_errors!(ctx, label, c.logged_errors)
            if c.error
                err = unwrap_load_error(c.value)
                print_repl_error(io, err, ctx.mod)
                record_error!(ctx, label, err)
                break
            end
            Core.eval(ctx.mod, Expr(:(=), :ans, QuoteNode(c.value)))
            if j == lastindex(group.exprs) && !suppress && c.value !== nothing
                # `invokelatest`: a fence that loads a package and displays one
                # of its values in the same fence (`using JET; @report_opt ...`)
                # defines the `show` method *after* this function's world age
                # was fixed, so a direct call would miss it and fall back to
                # the raw struct dump.
                Base.invokelatest(show, displayctx(io, ctx.mod), MIME"text/plain"(), c.value)
                println(io)
            end
        end
    end
    return String(take!(io))
end

# `?` mode: the docstring is looked up in the page module (so packages loaded
# by the page and functions defined on it are found) and rendered as the REPL
# renders it, ANSI colors included.
function exec_help(ctx::PageContext, code::AbstractString, label::AbstractString)
    io = IOBuffer()
    mod = ctx.mod
    for (k, query) in enumerate(filter(!isempty, map(strip, split(code, '\n'))))
        k > 1 && println(io)
        print(io, help_prompt(), query, '\n')
        c = capture() do
            expr = if hasmethod(REPL.helpmode, Tuple{IO, String, Module})
                REPL.helpmode(devnull, String(query), mod)
            else
                REPL.helpmode(devnull, String(query))
            end
            doc = Core.eval(mod, expr)
            Base.invokelatest(show, displayctx(stdout, mod), MIME"text/plain"(), doc)
            println()
        end
        print_captured(io, c.output)
        record_logged_errors!(ctx, label, c.logged_errors)
        if c.error
            err = unwrap_load_error(c.value)
            print_repl_error(io, err, mod)
            record_error!(ctx, label, err)
        end
    end
    return String(take!(io))
end

# `]` mode: one command per line, echoed behind the environment-aware prompt.
function exec_pkg(ctx::PageContext, code::AbstractString, label::AbstractString)
    io = IOBuffer()
    for (k, cmd) in enumerate(filter(!isempty, map(strip, split(code, '\n'))))
        k > 1 && println(io)
        print(io, pkg_prompt(), cmd, '\n')
        c = capture(() -> Pkg.REPLMode.pkgstr(String(cmd)))
        print_captured(io, c.output)
        record_logged_errors!(ctx, label, c.logged_errors)
        if c.error
            err = unwrap_load_error(c.value)
            print_repl_error(io, err, ctx.mod)
            record_error!(ctx, label, err)
        end
    end
    return String(take!(io))
end

# `;` mode: run through `sh -c` from the preprocessor's working directory,
# stdout and stderr merged, non-zero exit codes ignored like in the REPL.
function exec_shell(ctx::PageContext, code::AbstractString, label::AbstractString)
    io = IOBuffer()
    for (k, cmd) in enumerate(filter(!isempty, map(strip, split(code, '\n'))))
        k > 1 && println(io)
        print(io, shell_prompt(), cmd, '\n')
        buf = IOBuffer()
        try
            run(pipeline(ignorestatus(`sh -c $cmd`); stdout = buf, stderr = buf))
        catch err
            print_repl_error(buf, err, ctx.mod)
            record_error!(ctx, label, err)
        end
        print_captured(io, String(take!(buf)))
    end
    return String(take!(io))
end

# `!` mode: include silently, show the code as a plain ```julia block (minus
# `# hide` lines; `# hideall` hides the block entirely) and stdout, if any,
# as an output block. Results are never displayed, matching Xranklin.
function exec_plain(ctx::PageContext, code::AbstractString, label::AbstractString)
    lines = split(code, '\n')
    hideall = any(l -> occursin(HIDEALL_RE, l), lines)
    c = capture(() -> include_string(ctx.mod, code, String(label)))
    record_logged_errors!(ctx, label, c.logged_errors)
    err = c.error ? unwrap_load_error(c.value) : nothing
    err === nothing || record_error!(ctx, label, err)
    hideall && return ("", "")
    visible = [l for l in lines if !occursin(HIDE_RE, l)]
    while !isempty(visible) && isempty(strip(first(visible)))
        popfirst!(visible)
    end
    while !isempty(visible) && isempty(strip(last(visible)))
        pop!(visible)
    end
    code_md = isempty(visible) ? "" : string("```julia\n", join(visible, '\n'), "\n```")
    out = IOBuffer()
    print_captured(out, c.output)
    err === nothing || print_repl_error(out, err, ctx.mod)
    return (code_md, String(take!(out)))
end
