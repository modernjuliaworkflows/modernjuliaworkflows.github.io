@def title = "Writing your code"

# Writing your code

\toc

## Installation

> TLDR: Use `juliaup`

Do not install Julia from the official [downloads](https://julialang.org/downloads/) page, use **[`juliaup`](https://github.com/JuliaLang/juliaup)** instead.
You can get it from the Windows store, or from the command line on Unix systems:

```bash
curl -fsSL https://install.julialang.org | sh
```

It provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to download, update, organize and switch between Julia versions.
As a bonus, you no longer have to manually specify the path to your executable.

`juliaup` relies on adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact number.
Upon installation, the [current stable release](https://julialang.org/downloads/#current_stable_release) is downloaded and selected as the default:

```bash
juliaup add release  # done automatically
juliaup default release  # done automatically
```

However, you can use other versions like the [long-term support version](https://julialang.org/downloads/#long_term_support_release):

```bash
juliaup add lts
julia +lts  # launch lts
```

You can get an overview of the channels installed on your computer:

```bash
juliaup status
```

When new versions are tagged, the binding of a given channel can change, and a new executable might need to be downloaded.
If you want to catch up with the latest developments, that's easy:

```bash
juliaup update
```

## REPL

> TLDR: The REPL has 4 primary modes: Julia, package (`]`), help (`?`) and shell (`;`).

The Read-Eval-Print Loop (or REPL) is the most basic way to interact with Julia.
Check out its [documentation](https://docs.julialang.org/en/v1/stdlib/REPL/) for details, and the [REPL mastery workshop](https://github.com/miguelraz/REPLMasteryWorkshop) for a deep dive.
You can start one by typing `julia` into a terminal, or by clicking on the Julia application in your computer.
It will allow you to play around with arbitrary Julia code:

```>
a, b = 1, 2;
a + b
```

This is the standard, Julian mode of the REPL, but it also has three other modes.
Each mode is entered by typing a specific character after the `julia>` prompt, and can be exited by hitting backspace after the `julia>` prompt.

### Help mode (`?`)

By pressing `?` you can obtain information and metadata about Julia objects (functions, types, etc.), and unicode symbols.
The query fetches the docstring of the object, which explains how to use it.

```?
println
```

If you don't know the exact name you are looking for, type a word surrounded by quotes to see in which docstrings it pops up.

### Package mode (`]`)

By pressing `]` you access the package manager (check out its short [documentation](https://docs.julialang.org/en/v1/stdlib/Pkg/), we will get back to it later).
It is built into Julia and allows you to:

* `add`, `update` (or `up`) and `remove` (or `rm`) packages;
* `activate` different local, global or temporary environments;
* get the `status` (or `st`) of your current environment.

```]
activate --temp
status
add Example
status
```

### Shell mode (`;`)

By pressing `;` you enter a terminal, where you can execute any bash command you want.

```;
echo "hello"
ls ./pages
```

## Editor

> TLDR: VSCode has the best Julia support.

Most computer programs are just plain text files with a specific extension (in our case `.jl`).
So in theory, any text editor suffices to write and modify Julia code.
In practice, an Integrated Development Environment (or IDE) makes the experience much more pleasant, thanks to code-related utilities and language-specific plugins.

The best IDE for Julia is **[Visual Studio Code](https://code.visualstudio.com/)**, developed by Microsoft.
Indeed, the **[Julia VSCode extension](https://www.julia-vscode.org/)** is the most feature-rich and actively developed of all Julia IDE plugins.
You can download it from the VSCode Marketplace.
In what follows, we will often mention commands and keyboard shortcuts provided by this extension.
But the only shortcut you need to remember is `Ctrl + Shift + P` (or `Cmd + Shift + P` on Mac): this opens the VSCode command palette, in which you can search for any command.
Type "julia" in the command palette to see what you can do with it.

Assuming you want to avoid the Microsoft ecosystem, [VSCodium](https://vscodium.com/) is a nearly bit-for-bit replacement for VSCode, but with an open source license and without telemetry.
If you don't want to use VSCode at all, other options include [emacs](https://www.gnu.org/software/emacs/) and [vim](https://www.vim.org/).
Check out [JuliaEditorSupport](https://github.com/JuliaEditorSupport) to see if your favorite IDE has a Julia plugin.
The available functionalities should be roughly similar to those of VSCode, at least for the basic aspects like running code.

## Running code

> TLDR: Open a REPL and run all your code there interactively

You can execute a Julia script from your terminal, but in most cases that is not what you want to do.

```bash
julia myfile.jl
```

Julia has a rather high startup, load and compilation latency.
If you only use scripts, you will pay this cost every time you run a slightly modified version of your code.
That is why many Julia developers fire up a [REPL](#REPL) at the beginning of the day and run all of their code there, chunk by chunk, in an interactive way.
This is made much easier by IDE integration, and here are the relevant [VSCode commands](https://www.julia-vscode.org/docs/stable/userguide/runningcode/):

* `Julia: Start REPL` (shortcut `Alt + J` then `Alt + O`)
* `Julia: Execute Code in REPL and Move` (shortcut `Shift + Enter`). As in Jupyter, the code that gets executed is the block containing the cursor, or the selected part if there is any.
* `Julia: Execute active File in REPL`

When keeping the same REPL open for a long time, it's common to end up with a "polluted" workspace where the definitions of certain variables or functions have been overwritten in unexpected ways.
This, along with other events like `struct` redefinitions, might force you to restart your REPL now and again.
One way to help with workspace tidiness is to take advantage of the [module system](#local_packages) to separate the reusable parts of your code from the one-off parts that are only relevant for a certain script.

## Notebooks

> TLDR: Jupyter or Pluto, depending on your reactivity needs

Notebooks are a popular alternative to IDEs when it comes to short and self-contained code, typically in data science.
They are also a good fit for literate programming, where lines of code are interspersed by comments and explanations.

The most well-known notebook ecosystem is [Jupyter](https://jupyter.org/), which supports **Ju**lia, **Pyt**hon and **R** as its three core languages.
To use it with Julia, you will need to install the **[IJulia.jl](https://github.com/JuliaLang/IJulia.jl)** backend.
Then, if you have also installed Jupyter, you can run this command to launch the server:

```bash
jupyter notebook
```

If you only have IJulia.jl on your system, you can run this snippet instead:

```julia-repl
julia> using IJulia

julia> notebook()
```

A pure-Julia alternative to Jupyter is given by **[Pluto.jl](https://plutojl.org/)**.
Unlike Jupyter notebooks, Pluto notebooks are

* Reactive: when you update a cell, the other cells depending on it are updated.
* Reproducible: they come bundled with an exhaustive list of dependencies.

To try them out, install the package and then run

```julia-repl
julia> using Pluto

julia> Pluto.run()
```

## Environments

> TLDR: Julia projects are made with `] activate`, and their details are stored in the `Project.toml` and `Manifest.toml`.

Pkg.jl and the [Pkg mode](#package-mode) built in to the [REPL](#repl) let you install packages and manage environments.
A "package" is a structured way of reusing code between projects and the active "environment" is responsible for determining which versions of packages to load.

Pkg.jl can be used from the REPL, as seen before:
```]
activate MyPackage
```
or directly called in Julia mode as a package with the same commands:

```>
using Pkg
Pkg.activate("MyPackage")
```

The `activate` command used above can be used to activate an existing project or create a new one and then activate it.

You can also run `julia` from the command line with the [startup flag](#configuration) `--project MyProject` (which is what the [VSCode plugin](#environments_in_vscode) does).
After this, packages you install will be listed in the `Project.toml` and `Manifest.toml` files.

The `Project.toml` contains information both about the project e.g name, uuid, authors, and its dependencies.
Its dependency-related content is visible with `]status` or just `]st`
```]
add Term OhMyREPL
st
```

As dependencies often have their own dependencies, potential version conflicts must be resolved for an environment to be usable.
The resolution is done automatically on package installation with `]add `, environment instantiation with `]instantiate`, and with the `]resolve` command.
The output of this resolution is stored in the `Manifest.toml`.
<!-- , whose contents can be nicely visualised using [PkgDependency.jl](https://github.com/peng1999/PkgDependency.jl) -->

<!-- ```julia-repl
julia> using PkgDependency
julia> PkgDependency.tree("CSV")
 CSV v0.10.4
━━━━━━━━━━━━━
      │
      ├── InlineStrings v1.1.4
      │   └── Parsers v2.3.2
      ├── PooledArrays v1.4.2
      │   └── DataAPI v1.10.0
      ├── WeakRefStrings v1.4.2
      │   ├── DataAPI v1.10.0 (*)
      │   ├── InlineStrings v1.1.4 (*)
      │   └── Parsers v2.3.2 (*)
      ├── CodecZlib v0.7.0
      │   └── TranscodingStreams v0.9.8
      ├── Tables v1.7.0
      │   ├── DataAPI v1.10.0 (*)
      │   ├── OrderedCollections v1.4.1
      │   ├── IteratorInterfaceExtensions v1.0.0
      │   ├── DataValueInterfaces v1.0.0
      │   └── TableTraits v1.0.1
      │       └── IteratorInterfaceExtensions v1.0.0 (*)
      ├── FilePathsBase v0.9.19
      │   └── Compat v4.2.0
      ├── Parsers v2.3.2 (*)
      └── SentinelArrays v1.3.13
``` -->

Sharing a project between computers is as simple as sending a folder containing your code as well as the `Project.toml` and `Manifest.toml`.
With these files, the user can run `]instantiate` and Julia will perfectly[^1] recreate the state of packages in the local environment.

If you haven't `activate`d a local project, packages that you `add` will be installed in the "global environment" called `@v1.X`[^2] after the active version of Julia.
Packages installed globally are available no matter which local environment is active because of "environment stacking":

When calling `using Package`, Julia determines what to load by going down the stack defined by `Base.LOAD_PATH`:

```>
Base.LOAD_PATH
```

The search begins at the local environment `@`, then the global environment `@v#.#`, and finally the standard library `@stdlib` that comes pre-installed with Julia.
The two most important implications of this are firstly that development tools can be installed globally and [loaded on startup](#configuration) to be available to use, and secondly that packages in the standard library can be updated or fixed independently of the version of Julia you are using.

[^1]: Unless the `develop` command is used, which causes the project's dependencies to be stateful.
[^2]: The `@` before the name means that the environment is ["shared"], which means you can `activate` shared environments with the `--shared` flag and it is located in `~/.julia/environments`. Notably it does _not_ imply that it is part of the environment stack.

["shared"]: https://pkgdocs.julialang.org/v1/environments/#Shared-environments

### Environments in VSCode

In VSCode, if your directory contains a `Project.toml`, you will be prompted whether you want to make this the default environment.
With this option set, anytime you [open a REPL](#running-code) the environment will already be the local one.
<!-- How about other IDEs? -->

## Local packages

Local packages are a smart way of reusing code between projects.
You could load common code directly with `include("path/to/file.jl")`, but a local package allows you to benefit from package niceties:

1. You don't have to specify the path, you can just write `using MyPackage`,
2. You can [version](sharing/#Compatibility) the package and update it without breaking code that relies on old versions of the package,
3. You can add it as a dependency to a project that you're working on,
4. (Bonus!) You get used to developing reusable, modular code.

<!-- TODO: Creating, editing, and loading a new local package in a different project. -->
<!-- TODO: LocalRegistry? -->

## Configuration

Julia accepts [startup flags](https://docs.julialang.org/en/v1/manual/command-line-interface/#command-line-interface) to handle settings such as the number of threads available.
In addition, most Julia developers also have a [startup file](https://docs.julialang.org/en/v1/manual/command-line-interface/#Startup-file) which is run automatically every time the language is started.
It is located at `.julia/config/startup.jl`.

The basic component that everyone puts in the startup file is Revise.jl:

```julia
try
    using Revise
catch e
    @warn "Error initializing Revise"
end
```

In addition, users commonly load packages that affect the REPL experience, as well as benchmarking or profiling utilities.
We will come back to all of these later on, but in the meantime **[StartupCustomizer.jl](https://github.com/abraemer/StartupCustomizer.jl)** can help you set them up.
More generally, the startup file allows you to define your own favorite helper functions and have them immediately available in every Julia session.

## Esthetics

* [Term.jl](https://github.com/FedeClaudi/Term.jl)
* [OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl)
* [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl)
* [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)
* [ProgressLogging.jl](https://github.com/JuliaLogging/ProgressLogging.jl)
* [Suppressor.jl](https://github.com/JuliaIO/Suppressor.jl)

## Debugging

* [InteractiveCodeSearch.jl](https://github.com/tkf/InteractiveCodeSearch.jl)
* [InteractiveErrors.jl](https://github.com/MichaelHatherly/InteractiveErrors.jl)
* [CodeTracking.jl](https://github.com/timholy/CodeTracking.jl)
* [Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl)
* [Debugger.jl](https://github.com/JuliaDebug/Debugger.jl)
* [debugging in VSCode](https://www.julia-vscode.org/docs/stable/userguide/debugging/)

## Other languages

* [C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
* [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) + [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)
* [JuliaInterop](https://github.com/JuliaInterop) ([RCall.jl](https://github.com/JuliaInterop/RCall.jl), [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl))

## Getting help

* [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl)
* [cheatsheet](https://cheatsheet.juliadocs.org/)
* [help](https://julialang.org/about/help/)
* [community](https://julialang.org/community/)

```julia
#hideall
run(`rm -fr MyPackage`)
```