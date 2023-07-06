@def title = "Writing Julia code"

# Writing Julia code

\toc

## Installation

The most natural (but not the best) way to install Julia is the [downloads page](https://julialang.org/downloads/).
Don't forget to also read the platform-specific instructions for [Windows](https://julialang.org/downloads/platform/#windows), [macOS](https://julialang.org/downloads/platform/#macos) or [Linux](https://julialang.org/downloads/platform/#linux_and_freebsd).
This official page is where you will find the "current stable release", which everyone should use by default.
At the time of writing, it has the following version number:

```julia:version
@show VERSION
```
\output{version}

But of course new versions are released regularly, and you will need to keep up.
On the other hand, you may want to test your code on older versions and ensure compatibility.

The best way to manage multiple Julia versions on your computer is [juliaup](https://github.com/JuliaLang/juliaup).
You can get it from the [Windows store](https://github.com/JuliaLang/juliaup#windows), or install it from the [command line](https://github.com/JuliaLang/juliaup#mac-and-linux) on Unix systems.
It provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to organize, update and switch between Julia versions.
As a bonus, you no longer have to specify the path to your Julia executable: juliaup takes care of it in the background.

For instance, you can install the latest release candidate `rc` and the long-term support version `lts` as follows:
```
juliaup add rc
juliaup add lts
```
Once that is done, you can check the status of your installation:
```
juliaup status
```
The result will look somewhat like this:
```julia:juliaup_status
#hideall
run(`juliaup status`)
```
\output{juliaup_status}

As you can see, each named channel (`release`, `rc`, `lts`) is associated with a specific Julia version.
These versions can be updated with
```
juliaup update
```
The line marked with a star corresponds to the default version, the one that will be launched when you start Julia.
You can select it with
```
juliaup default lts
```

## Development environments

* [VSCode](https://code.visualstudio.com/) / [VSCodium](https://vscodium.com/) + [Julia VSCode extension](https://www.julia-vscode.org/)
* [emacs](https://www.gnu.org/software/emacs/) / [vim](https://www.vim.org/) / other IDEs + [JuliaEditorSupport](https://github.com/JuliaEditorSupport)
* [Jupyter](https://jupyter.org/) / [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
* [Pluto.jl](https://plutojl.org/)

## Loading and running

* [REPL](https://docs.julialang.org/en/v1/stdlib/REPL/)
* [Revise.jl](https://github.com/timholy/Revise.jl)
* [running in VSCode](https://www.julia-vscode.org/docs/stable/userguide/runningcode/)
* startup file

## Package management

* [Pkg.jl](https://github.com/JuliaLang/Pkg.jl)
* stacking environments
* [environments in VSCode](https://www.julia-vscode.org/docs/stable/userguide/env/)

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

## If you're lost

* [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl)
* [community spaces](https://julialang.org/community/)