"""
    ZolaPreprocessor

Preprocessor for modernjuliaworkflows: replays Xranklin's executable code
fences and emits ANSI-colored HTML, turning the authored markdown in `src/`
into plain markdown that Zola can build. See `tools/ZolaPreprocessor/README.md`
for the fence modes and the CLI.
"""
module ZolaPreprocessor

using ANSIColoredPrinters: HTMLPrinter
using IOCapture: IOCapture
using Logging: Logging, current_logger, with_logger
using Pkg: Pkg
using REPL: REPL

export process_page, process_tree

include("render.jl")
include("modes.jl")
include("page.jl")
include("cli.jl")

end # module ZolaPreprocessor
