@def title = "Writing Julia code"

# Writing Julia code

\toc

## Installation

* [official downloads](https://julialang.org/downloads/)
* [juliaup](https://github.com/JuliaLang/juliaup)

## Development environments

* [VSCode](https://code.visualstudio.com/) / [VSCodium](https://vscodium.com/) + [Julia VSCode extension](https://www.julia-vscode.org/)
* [emacs](https://www.gnu.org/software/emacs/) / [vim](https://www.vim.org/) / other IDEs + [JuliaEditorSupport](https://github.com/JuliaEditorSupport)
* [Jupyter](https://jupyter.org/) / [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
* [Pluto.jl](https://plutojl.org/)

<!-- It may be worth mentioning the REPL as a development environment here, or I could do it in the REPL section -->

## Loading and running

First here's some content on the [REPL](https://docs.julialang.org/en/v1/stdlib/REPL/).
It would be nice to link to the previous section by the fact that some people use it as a development environment making heavy use of `edit`.
Primarily, though, this section should talk about (some of) the different modes, and give examples of how to use them.
* Julian mode: Writing and running code.
    Lots to say but none of it very interesting as most people will interact with the REPL primarily from an IDE or one of the other modes.
* Help mode: Querying information about Julia objects --- to see their documentation, type information, and where they are defined --- and symbols --- to see how they are used or typed.
    It would be nice to have an example of each of these things.
* Pkg mode: Creating and managing packages and environments.
    More detail in section below so no example needed, just link to that section.
* Shell mode: Functions as a terminal inside Julia, you can also execude shell commands from Julian mode.
    An example of this is warranted but the rest is nicely explained by the first clause.

<!-- I believe Revise.jl makes more sense to talk about once the context of packages (particularly local packages) has been introduced. -->

<!-- The VSCode is important to write in tandem with or after the Development environments part is written to avoid overlap. -->
Most people develop Julia using a tool that allows for interactive development.
(Short explanation on what "Interactive development" means unless already covered in IDE section)
In VScode, you can [run code](https://www.julia-vscode.org/docs/stable/userguide/runningcode/) in the following useful ways:
* For interactive development, the standard way to use Julia, you can use hotkeys to run selections, lines, sections, or whole files in the currently open REPL.
    * Select a part of code to run only that part,
    * Put your cursor inside or after a language construct, such as a definition or function call, to run the whole construct,
    * Use the "run file in REPL" hotkey to do just that.
* You can run entire scripts from a new Julia session each time, but this isn't great as it takes a while to start a new REPL each time.
    To work with a (more or less) fresh workspace each time, you should bundle code into [local packages](#package-management).

Some code, however, you want to run on startup, every time Julia is loaded.
While VSCode has settings that allow you to specify startup flags, more powerful is its ability to automatically run a [startup file](https://docs.julialang.org/en/v1/manual/command-line-interface/#Startup-file).
This allows you to, among other things, load commonly used utility packages (some of which we will discuss later in this blog post):
```julia
using Revise
using OhMyREPL
```

Just remember that everything you put here is run every time, so it makes opening a little slower.
If you're using things only sometimes, then you should put them in conditional loaders (with ast transformations):
```julia
trust_me_bro()
```
<!-- The above paragraph is really useful, but might go over a few people's heads. Maybe we don't mention it and just provide people a copy-pasteable, highly commented startup.jl file -->

<!-- Where should discussion of `include`, `import` and `using` go? -->

## Package management

* [Pkg.jl](https://github.com/JuliaLang/Pkg.jl)
* stacking environments
* [environments in VSCode](https://www.julia-vscode.org/docs/stable/userguide/env/)
* [Revise.jl](https://github.com/timholy/Revise.jl)
<!-- We can talk about local packages here. I believe that it's a key part of the development experience (as my survey showed). -->

## Esthetics

* [Term.jl](https://github.com/FedeClaudi/Term.jl)
* [OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl)
* [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl)
* [InteractiveErrors.jl](https://github.com/MichaelHatherly/InteractiveErrors.jl)
* [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)

## Debugging

* [Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl)
* [Debugger.jl](https://github.com/JuliaDebug/Debugger.jl)
* [debugging in VSCode](https://www.julia-vscode.org/docs/stable/userguide/debugging/)

## Calling other languages

* [C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
* [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) + [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)
* [JuliaInterOp](https://github.com/JuliaInterop) ([RCall.jl](https://github.com/JuliaInterop/RCall.jl), [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl))

## Juliaspeak

* [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl)