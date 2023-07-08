@def title = "Writing Julia code"

# Writing Julia code

<!-- \toc -->

## Installation

```julia:version
#hideall
print(VERSION)
```

The most natural (but not the best) way to install Julia is the [downloads page](https://julialang.org/downloads/).
Don't forget to also read the platform-specific instructions for [Windows](https://julialang.org/downloads/platform/#windows), [macOS](https://julialang.org/downloads/platform/#macos) or [Linux](https://julialang.org/downloads/platform/#linux_and_freebsd).
This official page is where you will find the "current stable release", which everyone should use by default.
At the time of writing, it is version \textoutput{version}.
But of course new versions are released regularly, and you will need to keep up.
On the other hand, you may want to test your code on older versions and ensure compatibility.

There is an easy solution to manage multiple Julia versions on your computer, and it is called [juliaup](https://github.com/JuliaLang/juliaup).
You can get it from the [Windows store](https://github.com/JuliaLang/juliaup#windows), or install it from the [command line](https://github.com/JuliaLang/juliaup#mac-and-linux) on Unix systems.
It provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to organize, update and switch between Julia versions.
As a bonus, you no longer have to specify the path to your Julia executable: juliaup takes care of that for you.

The main thing to understand about juliaup is that it provides adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact number.
The most important ones are:
* `release`, which is bound to the [current stable release](https://julialang.org/downloads/#current_stable_release);
* `lts`, which is bound to the [long-term support version](https://julialang.org/downloads/#long_term_support_release).
* `rc`, which is bound to the upcoming release candidate;

For instance, you can install the LTS version with
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


<!-- We shoukd mention the REPL as a development environment here -->

## Running code

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
This allows you to, among other things, load packages that improves your development experience or contain functionality that you use very often.

It's tempting to put a lot of code in your `startup.jl` file for convenience's sake, but this convenience comes at a cost of increasing your startup time as it is executed.
To balance convenience and time, we can use AST transformations to conditionally load functionality from packages only when necessary.
We tell the REPL to listen for a set of user-defined functions or macros every time a command is sent to be executed;
when one is detected, before executing the command, it will first execute the corresponding `using` statement to allow the function or macro to be called.

```julia
ENV["JULIA_EDITOR"] = "code"

using Revise
using OhMyREPL

colorscheme!("GruvboxDark")
OhMyREPL.enable_pass!("RainbowBrackets", false)

if Base.isinteractive() &&
    (local REPL = get(Base.loaded_modules, Base.PkgId(Base.UUID("3fa0cd96-eef1-5676-8a61-b3b8758bbffb"), "REPL"), nothing); REPL !== nothing)

    # Automatically load tooling on demand:
    # - BenchmarkTools.jl when encountering @btime or @benchmark
    # - Cthulhu.jl when encountering @descend(_code_(typed|warntype))
    # - Debugger.jl when encountering @enter or @run
    # - Profile.jl when encountering @profile
    # - ProfileView.jl when encountering @profview
    local tooling_dict = Dict{Symbol,Vector{Symbol}}(
        :BenchmarkTools => Symbol.(["@btime", "@benchmark"]),
        :Cthulhu        => Symbol.(["@descend", "@descend_code_typed", "@descend_code_warntype"]),
        :Debugger       => Symbol.(["@enter", "@run"]),
        :Profile        => Symbol.(["@profile"]),
        :ProfileView    => Symbol.(["@profview"]),
    )
    pushfirst!(REPL.repl_ast_transforms, function(ast::Union{Expr,Nothing})
        function contains_macro(ast, m)
            return ast isa Expr && (
                (Meta.isexpr(ast, :macrocall) && ast.args[1] === m) ||
                any(x -> contains_macro(x, m), ast.args)
            )
        end
        for (mod, macros) in tooling_dict
            if any(contains_macro(ast, s) for s in macros) && !isdefined(Main, mod)
                @info "Loading $mod ..."
                try
                    Core.eval(Main, :(using $mod))
                catch err
                    @info "Failed to automatically load $mod" exception=err
                end
            end
        end
        return ast
    end)
end
```

<!-- Where should discussion of `include`, `import` and `using` go? -->
<!-- I think `include`, `import`, and `using` should go wherever modules are spoken about, which is the second -->

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

## Other languages

* [C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
* [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) + [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)
* [JuliaInterOp](https://github.com/JuliaInterop) ([RCall.jl](https://github.com/JuliaInterop/RCall.jl), [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl))

## Getting help

* [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl)
* [community spaces](https://julialang.org/community/)