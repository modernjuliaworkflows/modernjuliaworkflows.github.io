# Page processing: scan the authored markdown, execute fences, and pass
# everything else through untouched.

# Executable fences: exactly three backticks, a mode character, and a name
# that may contain any non-space characters (`$`, `-`, ...) or be empty.
const EXEC_FENCE_RE = r"^```([!>?\];])(\S*)\s*$"
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
# blocks even where a fence directly follows a paragraph.
function emit_html_block!(out::IOBuffer, html::AbstractString)
    isempty(html) && return nothing
    println(out)
    println(out, html)
    return nothing
end

function emit_exec_fence!(out::IOBuffer, ctx::PageContext, mode::Char, name::String,
                          code::String)
    label = isempty(name) ? string(mode) : name
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
    return nothing
end

"""
    process_page(text, relpath; pagedir, workdir) -> (output, errors)

Execute the fences of one authored page and return the markdown Zola should
build, plus the list of fence errors (rendered REPL-style in the output, but
reported so the build can summarize them).

If `pagedir` contains a `Project.toml`, that environment is active while the
page runs (restored afterwards). Fences run with the working directory set to
the page's subdirectory of `workdir`, so anything they create — generated
demo packages, files written by shell commands — lands in scratch space.
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
            body = lines[(i + 1):(closed ? j - 1 : j)]
            emit_exec_fence!(out, ctx, (mexec.captures[1]::SubString)[1],
                             String(mexec.captures[2]::SubString), join(body, '\n'))
            i = j + 1
        elseif mfence !== nothing
            j, closed = fence_extent(lines, i)
            info = strip(mfence.captures[2]::SubString)
            if info == "julia-repl" && length(mfence.captures[1]::SubString) == 3
                body = lines[(i + 1):(closed ? j - 1 : j)]
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

function process_page(text::AbstractString, relpath::AbstractString;
                      pagedir::AbstractString, workdir::AbstractString)
    lines = split(String(text), '\n')
    ctx = PageContext(make_sandbox(relpath), String(relpath), abspath(pagedir),
                      FenceError[])
    out = IOBuffer()
    pagework = normpath(joinpath(abspath(workdir), dirname(relpath)))
    mkpath(pagework)
    prev_project = Base.active_project()
    activated = isfile(joinpath(ctx.pagedir, "Project.toml"))
    if activated
        Pkg.activate(ctx.pagedir; io = devnull)
        Pkg.instantiate(; io = devnull)
    end
    try
        cd(() -> emit_page!(out, ctx, lines), pagework)
    finally
        if activated
            if prev_project === nothing
                Pkg.activate(; io = devnull)
            else
                Pkg.activate(dirname(prev_project); io = devnull)
            end
        end
    end
    output = string(rstrip(String(take!(out)), '\n'), '\n')
    return (output, ctx.errors)
end
