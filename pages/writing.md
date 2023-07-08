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

Depending on your experience and how you use Julia, some ways of writing code may be more familiar or useful to you than others.
Data scientists commonly prefer notebook environments such as those provided by [Jupyter](https://jupyter.org/) through the [IJulia.jl](https://github.com/JuliaLang/IJulia.jl) package, or Julia's own reactive notebooks from [Pluto.jl](https://plutojl.org/).
On the other hand, package developers or those who write a lot of scripts will prefer the more traditional programming environment provided by a text editor or integrated development environment (IDE).

For some, the Julia REPL (Read Evaluate Print Loop) itself is all that's necessary.
The REPL's primary function is to run code in "Julian" mode, but it also has a number of other modes that expand what can be done from inside Julia.
Each mode is enterred by typing a character into the REPL from Julian mode, and can be exited by deleting this character with backspace.

### Help mode (`?`)
By entering a `?`, you can query information and metadata about Julia objects and unicode symbols simply by typing their name into the command line.
For functions, types, and variables, the query fetches things such as documentation, type fields and supertypes, and in which file the object is defined.
<!-- How do you do syntax highlighting for the Julia REPL? -->
```
help?> Int
search: Int Int8 Int64 Int32 Int16 Int128 Integer intersect intersect!

  Int64 <: Signed


  64-bit signed integer type.
```

For unicode symbols, the query will return how to type the symbol in the REPL, which is useful when you copy-paste a symbol in without knowing its name, and fetch information about the object the symbol is bound to, just as above.

### Pkg mode (`]`)
Pkg mode is for managing environments and packages that is based on the Rust package manager "cargo".
By pressing `]` in Julian mode, you can `add`, `update` (or `up`) and `remove` (or `rm`) packages, `activate` different local or global environments, and get the `status` (or `st`) of your current environment.

More detail on using Pkg.jl and Pkg mode, see the [#Package-Management] section or the [#Setup] section of the [Sharing Julia code](./sharing.md#setup) post.

<!-- Check whether the second link is needed after writing both sections. -->

### Shell mode(`;`)
Shell mode: Functions as a terminal inside Julia, you can also execude shell commands from Julian mode.
Here's an example
```julia
an_example()
```

<!-- More needs to be written about the `edit` functionality of the REPL, I should talk to someone who does REPL-driven development. Miguel? -->

* [VSCode](https://code.visualstudio.com/) / [VSCodium](https://vscodium.com/) + [Julia VSCode extension](https://www.julia-vscode.org/)
* [emacs](https://www.gnu.org/software/emacs/) / [vim](https://www.vim.org/) / other IDEs + [JuliaEditorSupport](https://github.com/JuliaEditorSupport)
* [Jupyter](https://jupyter.org/) / [IJulia.jl](https://github.com/JuliaLang/IJulia.jl)
* [Pluto.jl](https://plutojl.org/)

## Running code

All executed Julia code ends up in a REPL[^1], but how it gets there can vary greatly.

[^1]: Unless you're compiling binaries with [StaticTools.jl](https://github.com/brenhinkeller/StaticTools.jl).

<!-- The VSCode is important to write in tandem with or after the Development environments part is written to avoid overlap. -->
Most people develop Julia using a tool that allows for [interactive development](https://en.wikipedia.org/wiki/Interactive_programming).
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