@def title = "Sharing your code"

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

Now it is time to leverage [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl), which automates package creation (like `]generate` on steroids).
The following code gives you a basic file structure to start with:

```>pkgtemplates
using PkgTemplates
t = Template(dir=".", user="myusername")
!isdir("MyAwesomePackage") ? t("MyAwesomePackage") : nothing
```

Then, you simply need to push this new folder to the remote repository MyAwesomePackage.jl, and you're ready to go.
The rest of this post will explain to you what each part of this folder does, and how to bend them to your will.
In particular, once you're done here, you will be able to run

```julia-repl
t = Template(dir=".", user="myusername", interactive=true)
```

and answer each interactive prompt confidently without freaking out.

## GitHub actions

The most useful aspect of PkgTemplates.jl is that it automatically generates workflows for [GitHub Actions](https://docs.github.com/en/actions/quickstart).
These are stored as YAML files in `.github/workflows`, with a slightly convoluted syntax that you don't need to fully understand.
For instance, the file `CI.yml` contains instructions that execute the tests of your package for each pull request, tag or push to the `main` branch.
This is done on a GitHub server and should theoretically cost you money, but your GitHub repository is public, you get an unlimited workflow budget for free.

The other default workflows are less relevant for new users, but we still mention them:

- [CompatHelper.jl](https://github.com/JuliaRegistries/CompatHelper.jl) monitors your dependencies and their versions.
- [TagBot](https://github.com/JuliaRegistries/TagBot) helps you manage package releases.

A very common workflow that is not present by default (but can be enabled manually) is building a documentation website and deploying it, more on that below.

## Code quality

* style guides ([BlueStyle](https://github.com/invenia/BlueStyle), [SciMLStyle](https://github.com/SciML/SciMLStyle))
* [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl)
* [formatting in VSCode](https://www.julia-vscode.org/docs/stable/userguide/formatter/)
* [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl)

## Testing

* [unit testing](https://docs.julialang.org/en/v1/stdlib/Test/)
* [TestEnv.jl](https://github.com/JuliaTesting/TestEnv.jl)
* [TestItemRunner.jl](https://github.com/julia-vscode/TestItemRunner.jl)
* [ReTest.jl](https://github.com/JuliaTesting/ReTest.jl)
* [ReferenceTests.jl](https://github.com/JuliaTesting/ReferenceTests.jl)

## Documentation

* [docstrings](https://docs.julialang.org/en/v1/manual/documentation/)
* [DocStringExtensions.jl](https://github.com/JuliaDocs/DocStringExtensions.jl)
* [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
* [LiveServer.jl](https://github.com/tlienart/LiveServer.jl)
* [Pollen.jl](https://github.com/lorenzoh/Pollen.jl)
* [Replay.jl](https://github.com/AtelierArith/Replay.jl)

## Literate programming

* [Literate.jl](https://github.com/fredrikekre/Literate.jl)
* [Weave.jl](https://github.com/JunoLab/Weave.jl)
* [Books.jl](https://github.com/JuliaBooks/Books.jl)
* [Quarto](https://quarto.org/)

## Compatibility

* [semantic versioning](https://semver.org/)
* [PackageCompatUI.jl](https://github.com/GunnarFarneback/PackageCompatUI.jl)
* [CompatHelper.jl](https://github.com/JuliaRegistries/CompatHelper.jl)
* [TagBot](https://github.com/JuliaRegistries/TagBot)
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