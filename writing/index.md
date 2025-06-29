+++
title = "Writing your code"
ignore_cache = true
+++

<!-- Setup -->

```!
# hideall
if isdir(sitepath("MyPackage"))
    rm(sitepath("MyPackage"); recursive=true)
end
```

\activate{}

# Writing your code

In this post, you will learn about tools to create, run and debug Julia code.

\toc

## Getting help

\tldr{You're not alone!}

Before you write any line of code, it's good to know where to find help.
The official [help page](https://julialang.org/about/help/) is a good place to start.
In particular, the Julia [community](https://julialang.org/community/) is always happy to guide beginners.

As a rule of thumb, the [Discourse forum](https://discourse.julialang.org/) is where you should ask your questions to make the answers discoverable for future users.
If you just want to chat with someone, you have a choice between the open source [Zulip](https://julialang.zulipchat.com/register/) and the closed source [Slack](https://julialang.org/slack/).
Some of the vocabulary used by community members may appear unfamiliar, but don't worry: [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl) gives you a good overview.

## Installation

\tldr{Use `juliaup`}

The most natural starting point to install Julia onto your system is the [Julia downloads page](https://julialang.org/downloads/), which will tell you to use [`juliaup`](https://github.com/JuliaLang/juliaup).

1. Windows users can download Julia and `juliaup` together from the [Windows Store](https://www.microsoft.com/store/apps/9NJNWW8PVKMN).
2. OSX or Linux users can execute the following terminal command:

```bash
curl -fsSL https://install.julialang.org | sh
```

In both cases, this will make the `juliaup` and `julia` commands accessible from the terminal (or Windows Powershell).
On Windows this will also create an application launcher.
All users can start Julia by running

```bash
julia
```

Meanwhile, `juliaup` provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to download, update, organize and switch between different Julia versions.
As a bonus, you no longer have to manually specify the path to your executable.
This all works thanks to adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact number.

For instance, the `release` channel will always point to the [current stable version](https://julialang.org/downloads/#current_stable_release), and the `lts` channel will always point to the [long-term support version](https://julialang.org/downloads/#long_term_support_release).
Upon installation of `juliaup`, the current stable version of Julia is downloaded and selected as the default.

\advanced{

To use other channels, add them to `juliaup` and put a `+` in front of the channel name when you start Julia:

```bash
juliaup add lts
julia +lts
```

You can get an overview of the channels installed on your computer with

```bash
juliaup status
```

When new versions are tagged, the version associated with a given channel can change, which means a new executable needs to be downloaded.
If you want to catch up with the latest developments, just do

```bash
juliaup update
```

}

## REPL

\tldr{The Julia REPL has 4 modes: Julia, package (`]`), help (`?`) and shell (`;`).}

The Read-Eval-Print Loop (or REPL) is the most basic way to interact with Julia, check out its [documentation](https://docs.julialang.org/en/v1/stdlib/REPL/) for details.
You can start a REPL by typing `julia` into a terminal, or by clicking on the Julia application in your computer.
It will allow you to play around with arbitrary Julia code:

```>repl-example
a, b = 1, 2;
a + b
```

This is the standard (Julia) mode of the REPL, but there are three other modes you need to know.
Each mode is entered by typing a specific character after the `julia>` prompt.
Once you're in a non-Julia mode, you stay there for every command you run.
To exit it, hit backspace after the prompt and you'll get the `julia>` prompt back.

### Help mode (`?`)

By pressing `?` you can obtain information and metadata about Julia objects (functions, types, etc.) or unicode symbols.
The query fetches the docstring of the object, which explains how to use it.

```?help-example
println
```

If you don't know the exact name you are looking for, type a word surrounded by quotes to see in which docstrings it pops up.

### Package mode (`]`)

By pressing `]` you access [Pkg.jl](https://github.com/JuliaLang/Pkg.jl), Julia's integrated package manager, whose [documentation](https://pkgdocs.julialang.org/v1/getting-started/) is an absolute must-read.
Pkg.jl allows you to:

* `]activate` different local, shared or temporary environments;
* `]instantiate` them by downloading the necessary packages;
* `]add`, `]update` (or `]up`) and `]remove` (or `]rm`) packages;
* get the `]status` (or `]st`) of your current environment.

As an illustration, we download the package Example.jl inside our current environment:

```]pkg-example
add Example
```

```]pkg-example
status
```

Note that the same keywords are also available in Julia mode:

```>pkg-example-2
using Pkg
Pkg.rm("Example")
```

The package mode itself also has a help mode, accessed with `?`, in case you're lost among all these new keywords.

### Shell mode (`;`)

By pressing `;` you enter a terminal, where you can execute any command you want.
Here's an example for Unix systems:

```;shell-example
ls ./writing
```

## Editor

\tldr{VSCode is the IDE with the best Julia support.}

Most computer programs are just plain text files with a specific extension (in our case `.jl`).
So in theory, any text editor suffices to write and modify Julia code.
In practice, an Integrated Development Environment (or IDE) makes the experience much more pleasant, thanks to code-related utilities and language-specific plugins.

The best IDE for Julia is [Visual Studio Code](https://code.visualstudio.com/), or VSCode, developed by Microsoft.
Indeed, the [Julia VSCode extension](https://www.julia-vscode.org/) is the most feature-rich of all Julia IDE plugins.
You can download it from the VSCode Marketplace and read its [documentation](https://www.julia-vscode.org/docs/stable/).

\vscode{

In what follows, we will sometimes mention commands and [keyboard shortcuts](https://www.julia-vscode.org/docs/stable/userguide/keybindings/) provided by this extension.
But the only shortcut you need to remember is `Ctrl + Shift + P` (or `Cmd + Shift + P` on Mac): this opens the VSCode command palette, in which you can search for any command.
Type "julia" in the command palette to see what you can do.

}

\advanced{

Assuming you want to avoid the Microsoft ecosystem, [VSCodium](https://vscodium.com/) is a nearly bit-for-bit replacement for VSCode, but with an open source license and without telemetry.
If you don't want to use VSCode at all, other options include [Emacs](https://www.gnu.org/software/emacs/) and [Vim](https://www.vim.org/).
Check out [JuliaEditorSupport](https://github.com/JuliaEditorSupport) to see if your favorite IDE has a Julia plugin.
The available functionalities should be roughly similar to those of VSCode, at least for the basic aspects like running code.

You may also want to download the [JuliaMono](https://juliamono.netlify.app/) font for esthetically pleasant unicode handling. 
}

## Running code

\tldr{Open a REPL and run all your code there interactively.}

You can execute a Julia script from your terminal, but in most cases that is not what you want to do.

```bash
julia myfile.jl  # avoid this
```

Julia has a rather high startup and compilation latency.
If you only use scripts, you will pay this cost every time you run a slightly modified version of your code.
That is why many Julia developers fire up a REPL at the beginning of the day and run all of their code there, chunk by chunk, in an interactive way.
Full files can be run interactively from the REPL with the `include` function.

```julia-repl
julia> include("myfile.jl")
```

Alternatively, `includet` from the [Revise.jl](https://timholy.github.io/Revise.jl/stable/user_reference/#Revise.includet) package can be used to "include and track" a file.
This will automatically update changes to function definitions in the file in the running REPL session.

\vscode{

[Running code](https://www.julia-vscode.org/docs/stable/userguide/runningcode/) is made much easier by the following commands:

* `Julia: Restart REPL` (shortcut `Alt + J` then `Alt + R`) - this will open or restart the integrated Julia REPL. It is different from opening a plain VSCode terminal and launching Julia manually from there.
* `Julia: Execute Code in REPL and Move` (shortcut `Shift + Enter`) - this will execute the selected code in the integrated Julia REPL, like a notebook.

}

When keeping the same REPL open for a long time, it's common to end up with a "polluted" workspace where the definitions of certain variables or functions have been overwritten in unexpected ways.
This, along with other events like `struct` redefinitions, might force you to restart your REPL now and again, and that's okay.

## Notebooks

\tldr{Try either Jupyter or Pluto, depending on your reactivity needs.}

Notebooks are a popular alternative to IDEs when it comes to short and self-contained code, typically in data science.
They are also a good fit for literate programming, where lines of code are interspersed with comments and explanations.

The most well-known notebook ecosystem is [Jupyter](https://jupyter.org/), which supports Julia, Python and R as its three core languages.
To use it with Julia, you will need to install the [IJulia.jl](https://github.com/JuliaLang/IJulia.jl) backend.
Then, if you have also [installed Jupyter](https://jupyter.org/install) with `pip install jupyterlab`, you can run this command to launch the server:

```bash
jupyter lab
```

If you only have IJulia.jl on your system, you can run this snippet instead:

```julia-repl
julia> using IJulia

julia> IJulia.notebook()
```

\vscode{

Jupyter notebooks can be opened, modified and run directly from the editor.
Thanks to the Julia extension, you don't even need to install IJulia.jl or Jupyter first.

}

A pure-Julia alternative to Jupyter is given by [Pluto.jl](https://plutojl.org/).
Unlike Jupyter notebooks, Pluto notebooks are

* Reactive: when you update a cell, the other cells depending on it are updated.
* Reproducible: they come bundled with an exhaustive list of dependencies that are installed automatically.

To try them out, install the package and then run

```julia-repl
julia> using Pluto

julia> Pluto.run()
```

## Markdown

\tldr{Markdown is also a good fit for literate programming, and Quarto is an alternative to notebooks.}

[Markdown](https://www.markdownguide.org/) is a markup language used to add formatting elements to plaintext text files.

### Plain Text Markdown
Plain text markdown files, which have the `.md` extension, are not used for interactive programming, meaning one cannot run code written in the file.
As a result, plain text markdown files are usually rendered into a final product by other software.

This is an example of a plain text markdown file:

````markdown
# Title

## Section Header

This is example text.

```julia
println("hello world")
```
````

### Quarto

[Quarto](https://quarto.org/) "is an open-source scientific and technical publishing system."
Quarto makes a plain text markdown file (`.md`) alternative called Quarto markdown file (`.qmd`).

Quarto markdown files like plain text markdown files also integrate with editors, such as VSCode.

\vscode{

Install the Quarto [extension](https://marketplace.visualstudio.com/items?itemName=quarto.quarto) for a streamlined experience.

}

Unlike plain text markdown files, Quarto markdown files have executable code chunks.
These code chunks provide a functionality similar to notebooks, thus Quarto markdown files are an alternative to notebooks.
Additionally, Quarto markdown files give users additional control over output and styling via the YAML header at the top of the `.qmd` file.

As of Quarto version 1.5, users can choose from two Julia engines to execute code - a native Julia engine and IJulia.jl.
The primary difference between the native Julia engine and IJulia.jl is that the native Julia engine does not depend on Python and can utilize local environments.
For this reason it's recommended to start with the native Julia engine.
Learn more about the native Julia engine in Quarto's [documentation](https://quarto.org/docs/blog/posts/2024-07-11-1.5-release/#native-julia-engine).

Below is an example of a Quarto markdown file.

````quarto
---
title: "My document"
format:
  # renders a HTML document
  html:
    # table of contents
    toc: true
execute:
  # makes code chunks invisible in the output
  # code output is still visible though
  echo: false
  # hides warnings in the output
  warning: false
# native julia engine
engine: julia
---

# Title

## Section Header

Below is an executable code chunk.

If this file were opened in an editor such as VSCode one could execute the `println("hello world")` Julia code and view the output, like in a notebook.

```{julia}
println("hello world")
```
````

## Environments

\tldr{Activate a local environment for each project with `]activate path`. Its details are stored in `Project.toml` and `Manifest.toml`.}

As we have seen, Pkg.jl is the Julia equivalent of `pip` or `conda` for Python.
It lets you [install packages](https://pkgdocs.julialang.org/v1/managing-packages/) and [manage environments](https://pkgdocs.julialang.org/v1/environments/) (collections of packages with specific versions).

You can activate an environment from the Pkg REPL by specifying its path `]activate somepath`.
Typically, you would do `]activate .` to activate the environment in the current directory.
Another option is to directly start Julia inside an environment, with the command line option `julia --project=somepath`.

Once in an environment, the packages you `]add` will be listed in two files `somepath/Project.toml` and `somepath/Manifest.toml`:

* `Project.toml` contains general project information (name of the package, unique id, authors) and direct dependencies with version bounds.
* `Manifest.toml` contains the exact versions of all direct and indirect dependencies

If you haven't entered any local project, packages will be installed in the default environment, called `@v1.X` after the active version of Julia (note the `@` before the name).
Packages installed that way are available no matter which local environment is active, because of "environment [stacking](https://docs.julialang.org/en/v1/manual/code-loading/#Environment-stacks)".
It is recommended to keep the default environment very light to avoid dependencies conflicts. It should contain only essential development tools.

\vscode{

You can configure the [environment](https://www.julia-vscode.org/docs/stable/userguide/env/) in which a VSCode Julia REPL opens.
Just click the `Julia env: ...` button at the bottom.
Note however that the Julia version itself will always be the default one from `juliaup`.

}

\advanced{

You can visualize the dependency graph of an environment with [PkgDependency.jl](https://github.com/peng1999/PkgDependency.jl).

}

## Local packages

\tldr{A package makes your code modular and reproducible.}

Once your code base grows beyond a few scripts, you will want to [create a package](https://pkgdocs.julialang.org/v1/creating-packages/) of your own.
The first advantage is that you don't need to specify the path of every file: `using MyPackage: myfunc` is enough to get access to the names you define.
Furthermore, you can specify versions for your package and its dependencies, making your code easier and safer to reuse.

To create a new package locally, one easy way is to use `]generate`. We will discuss more sophisticated workflows, including a graphical tool, in the next blog post.

```>generate-package
Pkg.generate(sitepath("MyPackage"));  # ignore sitepath
```

This command initializes a simple folder with a `Project.toml` and a `src` subfolder.
As we have seen, the `Project.toml` specifies the dependencies.
Meanwhile, the `src` subfolder contains a file `MyPackage.jl`, where a [module](https://docs.julialang.org/en/v1/manual/modules/) called `MyPackage` is defined.
It is the heart of your package, and will typically look like this when you're done:

```julia
module MyPackage

# imported dependencies
using OtherPackage1
using OtherPackage2

# files defining functions, types, etc.
include("file1.jl")
include("subfolder/file2.jl")

# names you want to make public
export myfunc
export MyType

end
```

## Development workflow

\tldr{Use Revise.jl to track code changes while you play with your package in its own environment.}

Once you have created a package, your daily routine will look like this:

1. Open a REPL in which you import `MyPackage`
2. Run some functions interactively, either by writing them directly in the REPL or from a Julia file that you use as a notebook
3. Modify some files in `MyPackage`
4. Go back to step 2

For that to work well, you need code modifications to be taken into account automatically.
That is why [Revise.jl](https://github.com/timholy/Revise.jl) exists.
In fact, it is used by so many Julia developers that some wish it were part of the core language: you can read its [documentation](https://timholy.github.io/Revise.jl/stable/) for more details.
If you start every REPL session by importing Revise.jl, then all the other packages you import after that will have their code tracked.
Whenever you edit a source file and hit save, the REPL will update its state accordingly.

\vscode{

The Julia extension imports Revise.jl by default when it starts a REPL, provided it is installed in the default environment.

}

The only remaining question is: in which environment should you work?
In general, you can work within the environment defined by your package, and add all the dependencies you need there.
To summarize, this is how you get started:

```julia
using Revise, Pkg
Pkg.activate("./MyPackage")
using MyPackage
MyPackage.myfunc()
```

\advanced{

There are situations where the previous method does not work:

* if you are developing several packages at once and want to use them together
* if your interactive work requires heavy dependencies that your package itself does not need (for instance plotting).

Then, you will need to use another environment as a playground, and `]develop` (or `]dev`) your package(s) into it.
Note the new Pkg.jl keyword: `]add PackageName` is used to download a fixed version of a registered package, while `]develop path` links to the current state of the code in a local folder.
To summarize, this is how you get started:

```julia
using Revise, Pkg
Pkg.activate("./MyPlayground")
Pkg.develop(path="./MyPackage")
using MyPackage
MyPackage.myfunc()
```

For the common case of dependencies needed for interactive work only, [shared](https://pkgdocs.julialang.org/v1/environments/#Shared-environments) or [stacked](https://docs.julialang.org/en/v1/manual/code-loading/#Environment-stacks) environments are another practical solution.
[ShareAdd.jl](https://github.com/Eben60/ShareAdd.jl) can help you in using and managing these (see its documentation).

}

## Configuration

\tldr{Use the startup file to import packages as soon as Julia starts.}

Julia accepts [startup flags](https://docs.julialang.org/en/v1/manual/command-line-interface/#command-line-interface) to handle settings such as the number of threads available or the environment in which it launches.
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

In addition, users commonly import packages that affect the REPL experience, as well as esthetic, benchmarking or profiling utilities.
A typical example is [OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl) which is widely used for syntax highlighting in the REPL.
More generally, the startup file allows you to define your own favorite helper functions and have them immediately available in every Julia session.
[StartupCustomizer.jl](https://github.com/abraemer/StartupCustomizer.jl) can help you set up your startup file.

\advanced{

Here are a few more startup packages that can make your life easier once you know the language better:

* [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl) allows you to shorten error stacktraces, which can sometimes get pretty long (beware of its [interactions with VSCode](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl/issues/38))
* [Term.jl](https://github.com/FedeClaudi/Term.jl) offers a completely new way to display things like types and errors (see the [advanced configuration](https://fedeclaudi.github.io/Term.jl/stable/adv/adv/) to enable it by default).

}

## Interactivity

\tldr{Explore source code from within the REPL.}

The Julia REPL comes bundled with [InteractiveUtils.jl](https://docs.julialang.org/en/v1/stdlib/InteractiveUtils/), a bunch of very useful functions for interacting with source code.

```!interactiveutils
using InteractiveUtils  # hide
```

Here are a few examples:

```>interactiveutils_examples
supertypes(Int64)
subtypes(Integer)
length(methodswith(Integer))
@which exp(1)
apropos("matrix exponential")
```

When you ask for help on a Julia forum, you might want to include your local Julia information:

```>
versioninfo()
```

\advanced{

The following packages can give you even more interactive power:

* [InteractiveCodeSearch.jl](https://github.com/tkf/InteractiveCodeSearch.jl) to look for a precise implementation of a function.
* [InteractiveErrors.jl](https://github.com/MichaelHatherly/InteractiveErrors.jl) to navigate through stacktraces.
* [CodeTracking.jl](https://github.com/timholy/CodeTracking.jl) to extend InteractiveUtils.jl

}

## Logging

\tldr{Logging macros are more versatile than printing.}

When you encounter a problem in your code or want to track progress, a common reflex is to add `print` statements everywhere.

```!printing_func
function printing_func(n)
    for i in 1:n
        println(i^2)
    end
end
```

```>printing_repl
printing_func(3)
```

A slight improvement is given by the `@show` macro, which displays the variable name:

```!showing_func
function showing_func(n)
    for i in 1:n
        @show i^2
    end
end
```

```>showing_repl
showing_func(3)
```

But you can go even further with the macros `@debug`, `@info`, `@warn` and `@error`.
They have several advantages over printing:

* They display variable names and a custom message
* They show the line number they were called from
* They can be disabled and filtered according to source module and severity level
* They work well in multithreaded code
* They can write their output to a file

```!warning_func
function warning_func(n)
    for i in 1:n
        @warn "This is bad" i^2
    end
end
```

```>warning_repl
warning_func(3)
```

Refer to the logging [documentation](https://docs.julialang.org/en/v1/stdlib/Logging/) for more information.

\advanced{

In particular, note that `@debug` messages are suppressed by default.
You can enable them through the `JULIA_DEBUG` environment variable if you specify the source module name, typically `Main` or your package module.

}

Beyond the built-in logging utilities, [ProgressLogging.jl](https://github.com/JuliaLogging/ProgressLogging.jl) has a macro `@progress`, which interfaces nicely with VSCode and Pluto to display progress bars.
And [Suppressor.jl](https://github.com/JuliaIO/Suppressor.jl) can sometimes be handy when you need to suppress warnings or other bothersome messages (use at your own risk).

## Debugging

\tldr{Infiltrator.jl and Debugger.jl allow you to peek inside a function while its execution is paused.}

The problem with printing or logging is that you cannot interact with local variables or save them for further analysis.
The following two packages solve this issue, and they probably belong in your default environment `@v1.X`, like Revise.jl.

### Setting

Assume you want to debug a function checking whether the $n$-th [Fermat number](https://en.wikipedia.org/wiki/Fermat_number) $F_n = 2^{2^n} + 1$ is prime:

```!fermat
function fermat_prime(n)
    k = 2^n
    F = 2^k + 1
    for d in 2:isqrt(F)  # integer square root
        if F % d == 0
            return false
        end
    end
    return true
end
```

```>fermat-test
fermat_prime(4)
fermat_prime(6)
```

Unfortunately, $F_4 = 65537$ is the largest known Fermat prime, which means $F_6$ is incorrectly classified.
Let's investigate why this happens!

### Infiltrator.jl

[Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl) is a lightweight inspection package, which will not slow down your code at all.
Its `@infiltrate` macro allows you to directly set breakpoints in your code.
Calling a function which hits a breakpoint will activate the Infiltrator REPL-mode
and change the prompt to `infil>`.
Typing `?` in this mode will summarize available commands.
For example, typing `@locals` in Infiltrator-mode will print local variables:

```julia
using Infiltrator

function fermat_prime_infil(n)
    k = 2^n
    F = 2^k + 1
    @infiltrate
    for d in 2:isqrt(F)
        if F % d == 0
            return false
        end
    end
    return true
end
```

What makes Infiltrator.jl even more powerful is the `@exfiltrate` macro, which allows you to move local variables into a global storage called the `safehouse`.

```julia-repl
julia> fermat_prime_infil(6)
Infiltrating fermat_prime_infil(n::Int64)
  at REPL[2]:4

infil> @exfiltrate k F
Exfiltrating 2 local variables into the safehouse.

infil> @continue

true

julia> safehouse.k
64

julia> safehouse.F
1
```

The diagnosis is a classic one: [integer overflow](https://docs.julialang.org/en/v1/manual/faq/#faq-integer-arithmetic).
Indeed, $2^{64}$ is larger than the maximum integer value in Julia:

```>typemax
typemax(Int)
2^63-1
```

And the solution is to call our function on "big" integers with an arbitrary number of bits:

```>fermat-big
fermat_prime(big(6))
```

### Debugger.jl

[Debugger.jl](https://github.com/JuliaDebug/Debugger.jl) allows us to interrupt code execution anywhere we want, even in functions we did not write.
Using its `@enter` macro, we can enter a function call and walk through the call stack, at the cost of reduced performance.

The REPL prompt changes to `1|debug>`, allowing you to use [custom navigation commands](https://github.com/JuliaDebug/Debugger.jl#debugger-commands) to step into and out of function calls, show local variables and set breakpoints.
Typing a backtick `` ` `` will change the prompt to `1|julia>`, indicating evaluation mode.
Any expression typed in this mode will be evaluated in the local context.
This is useful to show local variables, as demonstrated in the following example:

```julia-repl
julia> using Debugger

julia> @enter fermat_prime(6)
In fermat_prime(n) at REPL[7]:1
 1  function fermat_prime(n)
>2      k = 2^n
 3      F = 2^k + 1
 4      for d in 2:isqrt(F)  # integer square root
 5          if F % d == 0
 6              return false

About to run: (^)(2, 6)
1|debug> n
In fermat_prime(n) at REPL[7]:1
 1  function fermat_prime(n)
 2      k = 2^n
>3      F = 2^k + 1
 4      for d in 2:isqrt(F)  # integer square root
 5          if F % d == 0
 6              return false
 7          end

About to run: (^)(2, 64)
1|julia> k
64
```

\vscode{

VSCode offers a nice [graphical interface for debugging](https://www.julia-vscode.org/docs/stable/userguide/debugging/).
Click left of a line number in an editor pane to add a _breakpoint_, which is represented by a red circle.
In the debugging pane of the Julia extension, click `Run and Debug` to start the debugger.
The program will automatically halt when it hits a breakpoint.
Using the toolbar at the top of the editor, you can then _continue_, _step over_, _step into_ and _step out_ of your code.
The debugger will open a pane showing information about the code such as local variables inside of the current function, their current values and the full call stack.

The debugger can be [sped up](https://www.julia-vscode.org/docs/dev/userguide/debugging/#Settings-to-speed-up-the-debugger) by selectively compiling modules that you will not need to step into via the `+` symbol at the bottom of the debugging pane.
It is often easiest to start by adding `ALL_MODULES_EXCEPT_MAIN` to the compiled list, and then selectively remove the modules you need to have interpreted
by typing their name into the same `+` menu but with a `-` sign in front e.g. `-MyModule`.
}

<!-- Clean up -->
