# ANSI rendering: REPL-style prompts, and conversion of ANSI text into
# `<pre>` blocks with the same nested .sgrNN spans Xranklin emits today.

# Prompt text is wrapped in color + bold, closed by a full reset, which
# ANSIColoredPrinters turns into `<span class="sgrNN"><span class="sgr1">`.
ansi_prompt(text::AbstractString, color::Int) = string("\e[", color, "m\e[1m", text, "\e[0m ")

julia_prompt() = ansi_prompt("julia>", 32)
help_prompt() = ansi_prompt("help?>", 33)
shell_prompt() = ansi_prompt("shell>", 31)

# The pkg prompt carries the active environment's name, e.g. "(writing) pkg> ".
# `promptf` lives in Pkg's REPL extension on Julia ≥ 1.11.
function pkg_prompt()
    prompt = try
        ext = Base.get_extension(Pkg, :REPLExt)
        ext === nothing ? Pkg.REPLMode.promptf() : ext.promptf()
    catch
        proj = Base.active_project()
        string("(", proj === nothing ? "?" : basename(dirname(proj)), ") pkg> ")
    end
    return ansi_prompt(rstrip(prompt), 34)
end

function ansi_to_html(ansi::AbstractString, class::AbstractString)
    printer = HTMLPrinter(IOBuffer(String(ansi)); root_class = class)
    return sprint(show, MIME"text/html"(), printer)
end

# Wrap finished fence output; returns "" for empty output so callers skip it.
function repl_block_html(ansi::AbstractString; class::AbstractString = "julia-repl ansi")
    isempty(strip(ansi)) && return ""
    endswith(ansi, '\n') || (ansi *= '\n')
    return ansi_to_html(ansi, class)
end

# Hand-written ```julia-repl fences get their prompts colorized so they look
# identical to executed fences (and need no `julia-repl` grammar in Zola).
const STATIC_PROMPTS = [
    (r"^julia> ", 32),
    (r"^help\?> ", 33),
    (r"^shell> ", 31),
    (r"^(?:\([^)]+\) )?pkg> ", 34),
]

function colorize_repl_line(line::AbstractString)
    line = String(line)
    for (re, color) in STATIC_PROMPTS
        m = match(re, line)
        m === nothing && continue
        rest = SubString(line, 1 + ncodeunits(m.match))
        return string(ansi_prompt(rstrip(m.match), color), rest)
    end
    return line
end

function render_static_repl(body::Vector{<:AbstractString})
    ansi = join((colorize_repl_line(l) for l in body), '\n')
    return repl_block_html(ansi)
end
