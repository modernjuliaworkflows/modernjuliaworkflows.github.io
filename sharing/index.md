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
You should try to follow [package naming rules](https://pkgdocs.julialang.org/v1/creating-packages/#Package-naming-rules) and add a ".jl" extension at the end, like so: "MyAwesomePackage.jl".
Do not insert any files like `README.md`, `.gitignore` or `LICENSE.md`, this will be done for you in the next step.

Indeed, we can leverage [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl) to automate package creation (like `]generate` from Pkg.jl but on steroids).
The following code gives you a basic file structure to start with:

```>pkgtemplates1
using PkgTemplates
t = Template(user="myuser", interactive=false);  
```

```!pkgtemplates2
#hideall
t = Template(dir=Utils.path(:site), user="myuser", interactive=false);
```

```>pkgtemplates3
t("MyAwesomePackage")
```

Then, you simply need to push this new folder to the remote repository <https://github.com/myuser/MyAwesomePackage.jl>, and you're ready to go.

The steps described above, including creation of a GitHub repo and pushing your project to it, can also be comfortably done with the help of [PackageMaker.jl](https://github.com/Eben60/PackageMaker.jl), which is a graphical wrapper around [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl) with a couple features of its own.

The rest of this post will explain to you what each part of this folder does, and how to bend them to your will.

To work on the package further, we switch to it's environment or "develop" it into the current one, and then import it:

```julia-repl
julia> using Pkg # remember, you can equivalently do all that from the pkg REPL after pressing ]

julia> Pkg.activate(path="MyAwesomePackage") 
```

or 

```julia-repl
julia> using Pkg

julia> Pkg.develop(path="MyAwesomePackage")
```

```!using-awesome1
#hideall
using Pkg
Pkg.develop(path=sitepath("MyAwesomePackage"))  # ignore sitepath
```

```>using-awesome2
using MyAwesomePackage
```


## GitHub Actions

The most useful aspect of PkgTemplates.jl is that it automatically generates workflows for [GitHub Actions](https://docs.github.com/en/actions/quickstart).
These are stored as YAML files in `.github/workflows`, with a slightly convoluted syntax that you don't need to fully understand.
For instance, the file `CI.yml` contains instructions that execute the tests of your package (see below) for each pull request, tag or push to the `main` branch.
This is done on a GitHub server and should theoretically cost you money, but your GitHub repository is public, you get an unlimited workflow budget for free.

A variety of workflows and functionalities are available through optional [plugins](https://juliaci.github.io/PkgTemplates.jl/stable/user/#Plugins-1).
The interactive setting `Template(..., interactive=true)` allows you to select the ones you want for a given package.
Otherwise, you will get the [default selection](https://juliaci.github.io/PkgTemplates.jl/stable/user/#Default-Plugins), which you are encouraged to look at.

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

Such tests belong in `test/runtests.jl`, and they are executed with the `]test` command (in the REPL's Pkg mode).
Unit testing may seem rather naive, or even superfluous, but as your code grows more complex, it becomes easier to break something without noticing.
Testing each part separately will increase the reliability of the software you write.

\advanced{

To test the arguments provided to the functions within your code (for instance their sign or value), avoid `@assert` (which can be deactivated) and use [ArgCheck.jl](https://github.com/jw3126/ArgCheck.jl) instead.

}

At some point, your package may require [test-specific dependencies](https://pkgdocs.julialang.org/v1/creating-packages/#Adding-tests-to-the-package).
This often happens when you need to test compatibility with another package, on which you do not depend for the source code itself.
Or it may simply be due to testing-specific packages like the ones we will encounter below.
For interactive testing work, use [TestEnv.jl](https://github.com/JuliaTesting/TestEnv.jl) to activate the full test environment (faster than running `]test` repeatedly).

\vscode{

The Julia extension also has its own testing framework, which relies on sprinkling "test items" throughout the code.
See [TestItemRunner.jl](https://github.com/julia-vscode/TestItemRunner.jl) for indications on how to use them optimally.

}

\advanced{

If you want to have more control over your tests, you can try

* [ReferenceTests.jl](https://github.com/JuliaTesting/ReferenceTests.jl) to compare function outputs with reference files.
* [ReTest.jl](https://github.com/JuliaTesting/ReTest.jl) to define tests next to the source code and control their execution.
* [TestSetExtensions.jl](https://github.com/ssfrr/TestSetExtensions.jl) to make test set outputs more readable.
* [TestReadme.jl](https://github.com/thchr/TestReadme.jl) to test whatever code samples are in your README.
* [ReTestItems.jl](https://github.com/JuliaTesting/ReTestItems.jl) for an alternative take on VSCode's test item framework.

}

Code coverage refers to the fraction of lines in your source code that are covered by tests.
It is a good indicator of the exhaustiveness of your test suite, albeit not sufficient.
[Codecov](https://about.codecov.io/) is a website that provides easy visualization of this coverage, and many Julia packages use it.
It is available as a PkgTemplates.jl plugin, but you have to perform an [additional configuration step](https://docs.codecov.com/docs/adding-the-codecov-token) on the repo for Codecov to communicate with it.

\advanced{

For local coverage analysis, [LocalCoverage.jl](https://github.com/JuliaCI/LocalCoverage.jl) provides trivial functions for working with coverage locally without requiring external services.

}

## Style

To make your code easy to read, it is essential to follow a consistent set of guidelines.
The official [style guide](https://docs.julialang.org/en/v1/manual/style-guide/) is very short, so most people use third party style guides like [BlueStyle](https://github.com/JuliaDiff/BlueStyle) or [SciMLStyle](https://github.com/SciML/SciMLStyle).

[JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) is an automated formatter for Julia files which can help you enforce the style guide of your choice.
Just add a file `.JuliaFormatter.toml` at the root of your repository, containing a single line like

```toml
style = "blue"
```

Then, the package directory will be formatted in the BlueStyle whenever you call

```>format
using JuliaFormatter
JuliaFormatter.format(MyAwesomePackage)
```

\vscode{

The [default formatter](https://www.julia-vscode.org/docs/stable/userguide/formatter/) falls back on JuliaFormatter.jl.

}

\advanced{

You can format code automatically in GitHub pull requests with the [`julia-format` action](https://github.com/julia-actions/julia-format), or add the formatting check directly to your test suite.

}

## Code quality

Of course, there is more to code quality than just formatting.
[Aqua.jl](https://github.com/JuliaTesting/Aqua.jl) provides a set of routines that examine other aspects of your package, from unused dependencies to ambiguous methods.
It is usually a good idea to include the following in your tests:

```>aqua
using Aqua, MyAwesomePackage
Aqua.test_all(MyAwesomePackage)
```

Meanwhile, [JET.jl](https://github.com/aviatesk/JET.jl) is a complementary tool, similar to a static linter.
Here we focus on its [error analysis](https://aviatesk.github.io/JET.jl/stable/jetanalysis/), which can detect errors or typos without even running the code by leveraging type inference.
You can either use it in report mode (with a nice [VSCode display](https://www.julia-vscode.org/docs/stable/userguide/linter/#Runtime-diagnostics)) or in test mode as follows:

```>jet
using JET, MyAwesomePackage
JET.report_package(MyAwesomePackage)
JET.test_package(MyAwesomePackage)
```

Note that both Aqua.jl and JET.jl might pick up false positives: refer to their respective documentations for ways to make them less sensitive.

Finally, [ExplicitImports.jl](https://github.com/ericphanson/ExplicitImports.jl) can help you get rid of generic imports to specify where each of the names in your package comes from.
This is a good practice and makes your code more robust to name conflicts between dependencies.

\advanced{

For additional code quality tools, consider [ReLint.jl](https://github.com/RelationalAI-oss/ReLint.jl), which provides another linter for Julia code with different rules and checks compared to JET.jl.
You can also use [pre-commit](https://github.com/pre-commit/pre-commit) to set up hooks that automatically run code quality checks before each commit, ensuring consistent code standards across your project.

}

## Documentation

Even if your code does everything it is supposed to, it will be useless to others (and pretty soon to yourself) without proper documentation.
Adding [docstrings](https://docs.julialang.org/en/v1/manual/documentation/) everywhere needs to become a second nature.
This way, readers and users of your code can query them through the REPL help mode.
[DocStringExtensions.jl](https://github.com/JuliaDocs/DocStringExtensions.jl) provides a few shortcuts that can speed up docstring creation by taking care of the obvious parts.

```!docstring
"""
    myfunc(a, b; kwargs...)

One-line sentence describing the purpose of the function,
just below the (indented) signature.

More details if needed.
"""
function myfunc end;
```


However, package documentation is not limited to docstrings.
It can also contain high-level overviews, technical explanations, examples, tutorials, etc.
[Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) allows you to design a website for all of this, based on Markdown files contained in the `docs` subfolder of your package.
Unsurprisingly, its own [documentation](https://documenter.juliadocs.org/stable/) is excellent and will teach you a lot.
To build the documentation locally, just run

```julia-repl
julia> using Pkg

julia> Pkg.activate("docs")

julia> include("docs/make.jl")
```

Then, use [LiveServer.jl](https://github.com/tlienart/LiveServer.jl) from your package folder to visualize and automatically update the website as the code changes (similar to Revise.jl):

```julia-repl
julia> using LiveServer

julia> servedocs()
```

To host the documentation online easily, just select the [`Documenter` plugin](https://juliaci.github.io/PkgTemplates.jl/stable/user/#PkgTemplates.Documenter) from PkgTemplates.jl before creation.
Not only will this fill the `docs` subfolder with the right contents: it will also initialize a [GitHub Actions workflow](https://documenter.juliadocs.org/stable/man/hosting/#gh-pages-Branch) to build and deploy your website on [GitHub pages](https://pages.github.com/).
The only thing left to do is to [select the `gh-pages` branch as source](https://documenter.juliadocs.org/stable/man/hosting/#gh-pages-Branch).

\advanced{

You may find the following Documenter plugins useful:

1. [DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl) allows you to insert citations inside the documentation website from a BibTex file.
2. [DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl) allow you to cross-reference external documentations (Documenter and Sphinx).
 
Assuming you are looking for an alternative to Documenter.jl, you can try out [Pollen.jl](https://github.com/lorenzoh/Pollen.jl).
In another category, [Replay.jl](https://github.com/AtelierArith/Replay.jl) allows you to replay instructions entered into your terminal as an ASCII video, which is nice for tutorials.

}

## Literate programming

Scientific software is often hard to grasp, and the code alone may not be very enlightening.
Whether it is for package documentation or to write papers and books, you might want to interleave code with texts, formulas, images and so on.
In addition to the [Pluto.jl](https://github.com/fonsp/Pluto.jl) and [Jupyter](https://jupyter.org/) notebooks, take a look at [Literate.jl](https://github.com/fredrikekre/Literate.jl) to enrich your code with comments and translate it to various formats.
[Books.jl](https://github.com/JuliaBooks/Books.jl) is relevant to draft long documents.

For enhanced Pluto.jl workflows, [PlutoPapers.jl](https://github.com/mossr/PlutoPapers.jl) provides interactive and LaTeX-styled papers directly within Pluto notebooks, bridging the gap between computational documents and publication-ready papers.

[Quarto](https://quarto.org/) is an open-source scientific and technical publishing system that supports Python, R and Julia.
Quarto can render markdown files (`.md`), Quarto markdown files (`.qmd`), and Jupyter Notebooks (`.ipynb`) into documents (Word, PDF, presentations), web pages, blog posts, books, [and more](https://quarto.org/docs/output-formats/all-formats.html).
Additionally, Quarto makes it easy to share or [publish](https://quarto.org/docs/publishing/) rendered content to Github Pages, Netlify, Confluence, Hugging Face Spaces, among others.
[Quarto Pub](https://quartopub.com/) is a free publishing service for content created with Quarto.

## Versions and registration

The Julia community has adopted [semantic versioning](https://semver.org/), which means every package must have a version, and the version numbering follows strict rules.
The main consequence is that you need to specify [compatibility bounds](https://pkgdocs.julialang.org/v1/compatibility/) for your dependencies: this happens in the `[compat]` section of your `Project.toml`.
To initialize these bounds, use the `]compat` command in the Pkg mode of the REPL, or the package [PackageCompatUI.jl](https://github.com/GunnarFarneback/PackageCompatUI.jl).

As your package lives on, new versions of your dependencies will be released.
The [CompatHelper.jl](https://github.com/JuliaRegistries/CompatHelper.jl)  GitHub Action will help you monitor Julia dependencies and update your `Project.toml` accordingly.
In addition, [Dependabot](https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuring-dependabot-version-updates#enabling-dependabot-version-updates) can monitor the dependencies... of your GitHub actions themselves.
But don't worry: both are default plugins in the PkgTemplates.jl setup.

\advanced{

It may also happen that you incorrectly promise compatibility with an old version of a package.
To prevent that, the [julia-downgrade-compat](https://github.com/julia-actions/julia-downgrade-compat) GitHub action tests your package with the oldest possible version of every dependency, and verifies that everything still works.

}

If your package is useful to others in the community, it may be a good idea to register it, that is, make it part of the pool of packages that can be installed with

```julia-repl
pkg> add MyAwesomePackage  # made possible by registration
```

Note that unregistered packages can also be installed by anyone from the GitHub URL, but this a less reproducible solution:

```julia-repl
pkg> add https://github.com/myuser/MyAwesomePackage  # not ideal
```

To register your package, check out the [general registry](https://github.com/JuliaRegistries/General) guidelines.
The [Registrator.jl](https://github.com/JuliaRegistries/Registrator.jl) bot can help you automate the process.
Another handy bot, provided by default with PkgTemplates.jl, is [TagBot](https://github.com/JuliaRegistries/TagBot): it automatically tags new versions of your package following each registry release.
If you have performed the [necessary SSH configuration](https://documenter.juliadocs.org/stable/man/hosting/#travis-ssh), TagBot will also trigger documentation website builds following each release.

For more advanced release management workflows, you might want to explore tools from other ecosystems that work well with Julia:
[semantic-release](https://github.com/semantic-release/semantic-release) provides fully automated version management and package publishing, while [release-please](https://github.com/googleapis/release-please) can generate release PRs based on conventional commit specifications.
[JuliaRegisterChangelog](https://github.com/alex180500/JuliaRegisterChangelog) specifically combines automatic changelog generation with Julia package registration.

\advanced{

If your package is only interesting to you and a small group of collaborators, or if you don't want to make it public, you can still register it by setting up a local registry: see [LocalRegistry.jl](https://github.com/GunnarFarneback/LocalRegistry.jl).

}

## Reproducibility

Obtaining consistent and reproducible results is an essential part of experimental science.
[DrWatson.jl](https://github.com/JuliaDynamics/DrWatson.jl) is a general toolbox for running and re-running experiments in an orderly fashion.
We now explore a few specific issues that often arise.

A first hurdle is [random number generation](https://docs.julialang.org/en/v1/stdlib/Random/), which is not guaranteed to remain stable across Julia versions.
To ensure that the random streams remain exactly the same, you need to use [StableRNGs.jl](https://github.com/JuliaRandom/StableRNGs.jl).
Another aspect is dataset download and management.
The packages [DataDeps.jl](https://github.com/oxinabox/DataDeps.jl), [DataToolkit.jl](https://github.com/tecosaur/DataToolkit.jl) and [ArtifactUtils.jl](https://github.com/JuliaPackaging/ArtifactUtils.jl) can help you bundle non-code elements with your package.
A third thing to consider is proper citation and versioning.
Giving your package a DOI with [Zenodo](https://zenodo.org/) ensures that everyone can properly cite it in scientific publications.
Similarly, your papers should cite the packages you use as dependencies: [PkgCite.jl](https://github.com/SebastianM-C/PkgCite.jl) will help with that.

## Interoperability

To ensure compatibility with earlier Julia versions, [Compat.jl](https://github.com/JuliaLang/Compat.jl) is your best ally.

Making packages play nice with one another is a key goal of the Julia ecosystem.
Since Julia 1.9, this can be done with [package extensions](https://pkgdocs.julialang.org/v1/creating-packages/#Conditional-loading-of-code-in-packages-(Extensions)), which override specific behaviors based on the presence of a given package in the environment.
[PackageExtensionTools.jl](https://github.com/cjdoris/PackageExtensionTools.jl) eases the pain of setting up extensions.

Furthermore, the Julia ecosystem as a whole plays nice with other programming languages too.
[C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/) are natively supported.
Python can be easily interfaced with the combination of [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) and [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl).
Other language compatibility packages can be found in the [JuliaInterop](https://github.com/JuliaInterop) organization, like [RCall.jl](https://github.com/JuliaInterop/RCall.jl).

Part of interoperability is also flexibility and customization: the [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl) package gives a nice way to specify various options in TOML files.

\advanced{

Some package developers may need to define what kind of behavior they expect from a certain type, or what a certain method should do.
When writing it in the documentation is not enough, a formal testable specification becomes necessary.
This problem of "interfaces" does not yet have a definitive solution in Julia, but several options have been proposed: [Interfaces.jl](https://github.com/rafaqz/Interfaces.jl), [RequiredInterfaces.jl](https://github.com/Seelengrab/RequiredInterfaces.jl) and [PropCheck.jl](https://github.com/Seelengrab/PropCheck.jl) are all worth checking out.
    
}

## Collaboration

Once your package grows big enough, you might need to bring in some help.
Working together on a software project has its own set of challenges, which are partially addressed by a good set of ground rules liks [SciML ColPrac](https://github.com/SciML/ColPrac).
Of course, collaboration goes both ways: if you find a Julia package you really like, you are more than welcome to [contribute](https://julialang.org/contribute/) as well, for example by opening issues or submitting pull requests.

<!-- Clean up -->

```!cleanup
Pkg.rm("MyAwesomePackage")  # hide
```
