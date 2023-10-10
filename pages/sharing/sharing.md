+++
title = "Sharing your code"
ignore_cache = true
+++

<!-- Setup -->

```!
# hideall
if isdir(sitepath("MyAwesomePackage"))
    rm(sitepath("MyAwesomePackage"); recursive=true)
end
```

\activate{}

# Sharing your code

In this post, you will learn about tools to initialize, structure and distribute Julia packages.

\toc

## Setup

A vast majority of Julia packages are hosted on [GitHub](https://github.com/) (although less common, other options like [GitLab](https://gitlab.com/) are also possible).
GitHub is a platform for collaborative software development, based on the version control system [Git](https://git-scm.com/).
If you are unfamiliar with these technologies, check out the [GitHub documentation](https://docs.github.com/en/get-started/quickstart).

The first step is therefore [creating](https://github.com/new) an empty GitHub repository.
You should try to follow [package naming guidelines](https://pkgdocs.julialang.org/v1/creating-packages/#Package-naming-guidelines) and add a ".jl" extension at the end, like so: "MyAwesomePackage.jl".
Do not insert any files like `README.md`, `.gitignore` or `LICENSE.md`, this will be done for you in the next step.

Indeed, we can leverage [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl) to automate package creation (like `]generate` from Pkg.jl but on steroids).
The following code gives you a basic file structure to start with:

```!pkgtemplates
using PkgTemplates
dir = Utils.path(:site)  # replace with the folder of your choice
t = Template(dir=dir, user="myusername", interactive=false);  
t("MyAwesomePackage")
```

Then, you simply need to push this new folder to the remote repository <https://github.com/myusername/MyAwesomePackage.jl>, and you're ready to go.
The rest of this post will explain to you what each part of this folder does, and how to bend them to your will.

To work on the package further, we develop it into the current environment and import it:

```!using-awesome
using Pkg
Pkg.develop(path=sitepath("MyAwesomePackage"))  # ignore sitepath
using MyAwesomePackage
```

## GitHub Actions

The most useful aspect of PkgTemplates.jl is that it automatically generates workflows for [GitHub Actions](https://docs.github.com/en/actions/quickstart).
These are stored as YAML files in `.github/workflows`, with a slightly convoluted syntax that you don't need to fully understand.
For instance, the file `CI.yml` contains instructions that execute the tests of your package (see below) for each pull request, tag or push to the `main` branch.
This is done on a GitHub server and should theoretically cost you money, but your GitHub repository is public, you get an unlimited workflow budget for free.

More workflows and functionalities are available through optional [plugins](https://juliaci.github.io/PkgTemplates.jl/stable/user/#Plugins-1).
The interactive setting `Template(..., interactive=true)` allows you to select the ones you want for a given package.  

\advanced{

The other default workflows are less relevant for new users, but we still mention them:

* [CompatHelper.jl](https://github.com/JuliaRegistries/CompatHelper.jl) monitors your dependencies and their versions.
* [TagBot](https://github.com/JuliaRegistries/TagBot) helps you manage package releases.

}

## Testing

The purpose of the `test` subfolder in your package is [unit testing](https://docs.julialang.org/en/v1/stdlib/Test/): automatically checking that your code behaves the way you want it to.
For instance, if you write your own square root function, you may want to test that it gives the correct results for positive numbers, and errors for negative numbers.

```>sqrt
using Test

@test sqrt(4) ≈ 2

@testset "Invalid inputs" begin
    @test_throws DomainError sqrt(-1)
    @test_throws MethodError sqrt("abc")
end;
```

These tests belong in `test/runtests.jl`, and they are executed with the `]test` command (in the REPL's Pkg mode).
Unit testing may seem rather naive, or even superfluous, but as your code grows more complex, it becomes easier to break something without noticing.
Testing each part separately will increase the reliability of the software you write.

At some point, your package may require [test-specific dependencies](https://pkgdocs.julialang.org/v1/creating-packages/#Adding-tests-to-the-package).
This often happens when you need to test compatibility with another package, on which you do not depend for the source code itself.
Or it may simply be due to testing-specific packages like the ones we will encounter below.
For interactive testing work, use [TestEnv.jl](https://github.com/JuliaTesting/TestEnv.jl) to activate the full test environment (faster than running `]test` repeatedly).

\advanced{

If you want to have more control over your tests:

* [ReferenceTests.jl](https://github.com/JuliaTesting/ReferenceTests.jl) to compare function outputs with reference files.
* [ReTest.jl](https://github.com/JuliaTesting/ReTest.jl) to define tests next to the source code and control their execution.
* [TestItemRunner.jl](https://github.com/julia-vscode/TestItemRunner.jl) to leverage the testing interface of VSCode.

}

## Style

To make your code easy to read, it is essential to follow a consistent set of guidelines.
The official [style guide](https://docs.julialang.org/en/v1/manual/style-guide/) is very short, so most people use third party style guides like [BlueStyle](https://github.com/invenia/BlueStyle) or [SciMLStyle](https://github.com/SciML/SciMLStyle).

[JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) is an automated formatter for Julia files which can help you enforce the style guide of your choice.
Just add a file `.JuliaFormatter.toml` at the root of your repository, containing a single line like

```toml
style = "blue"
```

Then, the package directory will be formatted in the BlueStyle whenever you call

```!format
using JuliaFormatter
JuliaFormatter.format(MyAwesomePackage)
```

\vscode{

The [default formatter](https://www.julia-vscode.org/docs/stable/userguide/formatter/) falls back on JuliaFormatter.jl.

}

\advanced{

You can format code automatically in GitHub pull requests with the [`julia-format` action](https://github.com/julia-actions/julia-format).

}

## Code quality

Of course, there is more to code quality than just formatting.
[Aqua.jl](https://github.com/JuliaTesting/Aqua.jl) provides a set of routines that examine other aspects of your package, from unused dependencies to ambiguous methods.
It is usually a good idea to include the following in your tests:

```!aqua
using Aqua
Aqua.test_all(MyAwesomePackage)
```

Meanwhile, [JET.jl](https://github.com/aviatesk/JET.jl) is a complementary tool, similar to a static linter.
Here we focus on its [error analysis](https://aviatesk.github.io/JET.jl/stable/jetanalysis/), which can detect errors or typos without even running the code by leveraging type inference.
You can either use it in report mode (with a nice [VSCode display](https://www.julia-vscode.org/docs/stable/userguide/linter/#Runtime-diagnostics)) or in test mode as follows:

```!jet
using JET
JET.report_package(MyAwesomePackage)
JET.test_package(MyAwesomePackage)
```

Note that both Aqua.jl and JET.jl might pick up false positives: refer to their respective documentations for ways to make them less sensitive.

## Documentation

Even if your code does everything it is supposed to, it will be useless to others (and pretty soon to yourself) without proper documentation.
Adding [docstrings](https://docs.julialang.org/en/v1/manual/documentation/) everywhere needs to be a second nature.

```!docstring
"""
    myfunc(a, b; kwargs...)

One-line sentence describing the purpose of the function,
just below the (indented) signature.

More details if needed.
"""
function myfunc end;
```

This way, readers and users of your code can query them through the REPL help mode:

```?
myfunc
```

[DocStringExtensions.jl](https://github.com/JuliaDocs/DocStringExtensions.jl) provides a few shortcuts that can speed up docstring creation by taking care of the obvious parts.

However, package documentation is not limited to docstrings.
It can also contain high-level overviews, technical explanations, examples, tutorials, etc.
[Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) allows you to design a website for all of this, based on Markdown files contained in the `docs` subfolder of your package.
Unsurprisingly, its own [documentation](https://documenter.juliadocs.org/stable/) is excellent and will teach you a lot.
To build the documentation locally, just run

```julia
using Pkg
Pkg.activate("docs")
include("docs/make.jl")
```

then open the file `docs/build/index.html` in your favorite browser.
An alternative is to use [LiveServer.jl](https://github.com/tlienart/LiveServer.jl) which automatically updates the website as the code changes (similar to Revise.jl).

To host the documentation online, just select the [`Documenter` plugin](https://juliaci.github.io/PkgTemplates.jl/stable/user/#PkgTemplates.Documenter) from PkgTemplates.jl.
Not only will this fill the `docs` subfolder with the right contents: it will also initialize a [GitHub Actions workflow](https://documenter.juliadocs.org/stable/man/hosting/#gh-pages-Branch) to build and deploy your website on [GitHub pages](https://pages.github.com/).
The only thing left to do is to [select the `gh-pages` branch as source](https://documenter.juliadocs.org/stable/man/hosting/#gh-pages-Branch).

\advanced{

Assuming you are looking for an alternative to Documenter.jl, you can try out [Pollen.jl](https://github.com/lorenzoh/Pollen.jl).
In another category, [Replay.jl](https://github.com/AtelierArith/Replay.jl) allows you to replay instructions entered into your terminal as an ASCII video, which is nice for tutorials.

}

## Literate programming

* [Literate.jl](https://github.com/fredrikekre/Literate.jl)
* [Weave.jl](https://github.com/JunoLab/Weave.jl)
* [Books.jl](https://github.com/JuliaBooks/Books.jl)
* [Quarto](https://quarto.org/)

## Compatibility

* [semantic versioning](https://semver.org/)
* [PackageCompatUI.jl](https://github.com/GunnarFarneback/PackageCompatUI.jl)
* [SimpleUnPack.jl](https://github.com/devmotion/SimpleUnPack.jl)

## Extensions

* [Requires.jl](https://github.com/JuliaPackaging/Requires.jl)
* [package extensions](https://pkgdocs.julialang.org/v1/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions))
* [PackageExtensionTools.jl](https://github.com/cjdoris/PackageExtensionTools.jl)

## Reproducibility

* [StableRNGs.jl](https://github.com/JuliaRandom/StableRNGs.jl)
* [DataDeps.jl](https://github.com/oxinabox/DataDeps.jl)
* [ArtifactUtils.jl](https://github.com/JuliaPackaging/ArtifactUtils.jl)
* [DrWatson.jl](https://github.com/JuliaDynamics/DrWatson.jl)
* containers?

## Publishing

* [general registry](https://github.com/JuliaRegistries/General)
* [Registrator.jl](https://github.com/JuliaRegistries/Registrator.jl)
* [LocalRegistry.jl](https://github.com/GunnarFarneback/LocalRegistry.jl)

## Collaboration

* [SciML ColPrac](https://github.com/SciML/ColPrac)
* [contribute](https://julialang.org/contribute/)
* [GitHub PRs](https://kshyatt.github.io/post/firstjuliapr/)

## Citations

* [Zenodo](https://zenodo.org/)
* [PkgCite.jl](https://github.com/SebastianM-C/PkgCite.jl)
* [DocumenterCitations.jl](https://github.com/ali-ramadhan/DocumenterCitations.jl)

## Composability

* [Interfaces.jl](https://github.com/rafaqz/Interfaces.jl)
* [RequiredInterfaces.jl](https://github.com/Seelengrab/RequiredInterfaces.jl)
* [PropCheck.jl](https://github.com/Seelengrab/PropCheck.jl)

## Other languages

* [C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
* [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) + [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)
* [JuliaInterop](https://github.com/JuliaInterop) ([RCall.jl](https://github.com/JuliaInterop/RCall.jl), [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl))

<!-- Clean up -->

```!cleanup
Pkg.rm("MyAwesomePackage")  # hide
```
