# Page processing: scan the authored markdown, execute fences, and pass
# everything else through untouched.

# A structurally broken fence: unclosed, or an executable fence with trailing
# junk. These always abort the page (and thereby fail the build) — unlike
# fence *code* that errors, which is reported via `PageContext.errors`.
struct FenceSyntaxError <: Exception
    page::String
    line::Int
    message::String
end
Base.showerror(io::IO, e::FenceSyntaxError) =
    print(io, e.page, ":", e.line, ": ", e.message)

# Executable fences: exactly three backticks, a mode character, and a name
# that may contain any non-space characters (`$`, `-`, ...) or be empty.
# An ` allow-error` flag marks a fence whose code is expected to error: the
# error renders REPL-style instead of failing the build.
const EXEC_FENCE_RE = r"^```([!>?\];])(\S*)(?:\s+(allow-error))?\s*$"
const FENCE_OPEN_RE = r"^(`{3,})(.*)$"
const FENCE_CLOSE_RE = r"^(`{3,})\s*$"

# Franklin-era build directives; handled by Xranklin, not by us. They are
# dropped from the output (they were never content) with a warning so the
# migration can't silently leave one behind.
const LEGACY_LINE_RE = r"^\\(toc|activate\{\})\s*$"

# Extent of the fence opened at `lines[i]`: index of its closing line and
# whether one was found (CommonMark: the closer needs at least as many ticks).
function fence_extent(lines::Vector{<:AbstractString}, i::Int)
    opener = match(FENCE_OPEN_RE, lines[i])::RegexMatch
    ticks = length(opener.captures[1]::SubString)
    for j in (i + 1):length(lines)
        m = match(FENCE_CLOSE_RE, lines[j])
        m !== nothing && length(m.captures[1]::SubString) >= ticks && return (j, true)
    end
    return (length(lines), false)
end

# Raw-HTML blocks are preceded by a blank line so they stay standalone HTML
# blocks even where a fence directly follows a paragraph. Content markdown is
# Tera-templated in Zola 0.23, and fence output can print `{{`/`{%`/`{#`, so
# every emitted block is wrapped in `{% raw %}` to keep Tera out of it.
function emit_html_block!(out::IOBuffer, html::AbstractString)
    isempty(html) && return nothing
    println(out)
    println(out, "{% raw %}")
    println(out, html)
    println(out, "{% endraw %}")
    return nothing
end

function emit_exec_fence!(
        out::IOBuffer, ctx::PageContext, mode::Char, name::String,
        code::String, allow_error::Bool
    )
    label = isempty(name) ? string(mode) : name
    nerrors = length(ctx.errors)
    if mode == '!'
        code_md, output = exec_plain(ctx, code, label)
        if !isempty(code_md)
            println(out)
            println(out, code_md)
        end
        emit_html_block!(out, repl_block_html(output; class = "code-output ansi"))
    else
        ansi = mode == '>' ? exec_julia(ctx, code, label) :
            mode == '?' ? exec_help(ctx, code, label) :
            mode == ']' ? exec_pkg(ctx, code, label) :
            exec_shell(ctx, code, label)
        emit_html_block!(out, repl_block_html(ansi))
    end
    if allow_error
        if length(ctx.errors) > nerrors
            resize!(ctx.errors, nerrors)
        else
            @warn "fence is marked `allow-error` but did not error" page = ctx.relpath fence = label
        end
    end
    return nothing
end

"""
    process_page(text, relpath; pagedir, workdir) -> (output, errors)

Execute the fences of one authored page in the current process and return
the markdown Zola should build, plus the list of fence errors (rendered
REPL-style in the output, and reported so the build can fail on them).
Errors in fences marked `allow-error` are sanctioned and not reported.
Structurally broken fences — unclosed, or an executable fence with trailing
junk — throw a [`FenceSyntaxError`](@ref) instead.

Fences run with the working directory set to the page's subdirectory of
`workdir`, so anything they create — generated demo packages, files written
by shell commands — lands in scratch space. The page's environment is not
managed here: [`process_tree`](@ref) runs each page on a worker process
whose load path is fixed to the page's environment at spawn.
"""
# The scan loop lives in its own function rather than a closure inside `cd`:
# the loop counter would be boxed by the closure, hiding every type from
# static analysis.
function emit_page!(out::IOBuffer, ctx::PageContext, lines::Vector{SubString{String}})
    i = 1
    n = length(lines)
    # Front matter passes through untouched.
    if n >= 1 && strip(lines[1]) == "+++"
        println(out, lines[1])
        i = 2
        while i <= n
            println(out, lines[i])
            i += 1
            strip(lines[i - 1]) == "+++" && break
        end
    end
    while i <= n
        line = lines[i]
        mexec = match(EXEC_FENCE_RE, line)
        mfence = match(FENCE_OPEN_RE, line)
        if mexec !== nothing
            j, closed = fence_extent(lines, i)
            closed || throw(FenceSyntaxError(ctx.relpath, i, "unclosed fence `$line`"))
            body = lines[(i + 1):(j - 1)]
            emit_exec_fence!(
                out, ctx, (mexec.captures[1]::SubString)[1],
                String(mexec.captures[2]::SubString), join(body, '\n'),
                mexec.captures[3] !== nothing
            )
            i = j + 1
        elseif mfence !== nothing
            j, closed = fence_extent(lines, i)
            closed || throw(FenceSyntaxError(ctx.relpath, i, "unclosed fence `$line`"))
            info = strip(mfence.captures[2]::SubString)
            exact = length(mfence.captures[1]::SubString) == 3
            # A three-backtick fence whose info string starts with a mode
            # character but did not parse as an executable fence is a typo
            # (bad flag, stray space), not content.
            if exact && !isempty(info) && info[1] in "!>?];"
                throw(
                    FenceSyntaxError(
                        ctx.relpath, i,
                        "malformed executable fence `$line`; expected ```<mode><name> with an optional ` allow-error` flag"
                    )
                )
            end
            if exact && info == "julia-repl"
                body = lines[(i + 1):(j - 1)]
                emit_html_block!(out, render_static_repl(body))
            else
                foreach(l -> println(out, l), lines[i:j])
            end
            i = j + 1
        elseif match(LEGACY_LINE_RE, strip(line)) !== nothing
            @warn "dropping leftover Franklin directive" page = ctx.relpath line
            i += 1
        else
            println(out, line)
            i += 1
        end
    end
    return nothing
end

function process_page(
        text::AbstractString, relpath::AbstractString;
        pagedir::AbstractString, workdir::AbstractString
    )
    lines = split(String(text), '\n')
    ctx = PageContext(
        make_sandbox(relpath), String(relpath), abspath(pagedir),
        FenceError[]
    )
    out = IOBuffer()
    pagework = normpath(joinpath(abspath(workdir), dirname(relpath)))
    mkpath(pagework)
    cd(() -> emit_page!(out, ctx, lines), pagework)
    output = string(rstrip(String(take!(out)), '\n'), '\n')
    return (output, ctx.errors)
end
