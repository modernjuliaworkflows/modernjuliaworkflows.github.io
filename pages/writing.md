@def title = "Writing Julia code"

# Writing Julia code

<!-- \toc -->

## Installation

\tldr{Use [juliaup](https://github.com/JuliaLang/juliaup)}

```julia:version
#hideall
print(VERSION)
```

The official [downloads page](https://julialang.org/downloads/) is where you can get Julia's current stable release[^1].
At the time of writing, it is version \textoutput{version}.
But of course, new versions are released regularly, and you will need to keep up.
In addition, you may want to test your code on older versions to ensure compatibility.

Therefore, we recommend you manage Julia with a tool called [juliaup](https://github.com/JuliaLang/juliaup).
You can get it from the [Windows store](https://github.com/JuliaLang/juliaup#windows), or install it from the [command line](https://github.com/JuliaLang/juliaup#mac-and-linux) on Unix systems.
It provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to download, update, organize and switch between Julia versions.
As a bonus, you no longer have to specify the path to your Julia executable: juliaup takes care of that for you.

The defining feature of juliaup is that it provides adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact number.
You only need to know two of them:

* `release`, which is bound to the [current stable release](https://julialang.org/downloads/#current_stable_release);
* `lts`, which is bound to the [long-term support version](https://julialang.org/downloads/#long_term_support_release).

For instance, you can install the long-term support version with

```bash
juliaup add lts
```

When new versions are tagged, the binding of a given channel can change, and a new executable might need to be downloaded.
If you want to catch up with the latest developments, all it takes is to run

```bash
juliaup update
```

If you want an overview of the channels installed on your computer, just use

```bash
juliaup status
```

## Development environments

* [VSCode](https://code.visualstudio.com/) / [VSCodium](https://vscodium.com/) + [Julia VSCode extension](https://www.julia-vscode.org/)
* [emacs](https://www.gnu.org/software/emacs/) / [vim](https://www.vim.org/) / other IDEs + [JuliaEditorSupport](https://github.com/JuliaEditorSupport)
* [Jupyter](https://jupyter.org/) / [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
* [Pluto.jl](https://plutojl.org/)

## Running code

* [REPL](https://docs.julialang.org/en/v1/stdlib/REPL/)
* [Revise.jl](https://github.com/timholy/Revise.jl)
* [running in VSCode](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
* startup file

## Environment and Package Management

* [Pkg.jl](https://github.com/JuliaLang/Pkg.jl)
* stacking environments
* [environments in VSCode](https://www.julia-vscode.org/docs/stable/userguide/env/)
* [Revise.jl](https://github.com/timholy/Revise.jl)

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

## Other languages

* [C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
* [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) + [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)
* [JuliaInterOp](https://github.com/JuliaInterop) ([RCall.jl](https://github.com/JuliaInterop/RCall.jl), [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl))

## Getting help

* [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl)
* [community spaces](https://julialang.org/community/)

[^1]: Don't forget to also read the platform-specific instructions for [Windows](https://julialang.org/downloads/platform/#windows), [macOS](https://julialang.org/downloads/platform/#macos) or [Linux](https://julialang.org/downloads/platform/#linux_and_freebsd).
