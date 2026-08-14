# Contributing

If you want to contribute to the blog, start by filing an issue to discuss potential additions.
Then, you can open a pull request.

The pages under `src/` are written in Markdown with executable code blocks, documented below.

## Building the site locally

MoJuWo is built using Julia 1.12 and [Zola](https://www.getzola.org/documentation/getting-started/installation/) `v0.23`.

Install the preprocessor's dependencies once:

```bash
julia --project=MoJuWoPreprocessor -e 'using Pkg; Pkg.instantiate()'
```

Then, from the repository root:

```bash
julia --project=MoJuWoPreprocessor -m MoJuWoPreprocessor serve
```

The site is built in two steps:

1. a Julia preprocessor ([MoJuWoPreprocessor](MoJuWoPreprocessor/README.md)) executes the code blocks in the authored pages under `src/` and writes the results to the gitignored `content/` directory;
2. [Zola](https://www.getzola.org) renders `content/` into the static site.

This executes every page (the first pass will take some time),
serves the site, and watches `src/`:
saving a page re-runs just that page and live-reloads the browser.
See [MoJuWoPreprocessor/README.md](MoJuWoPreprocessor/README.md) for the remaining commands (e.g., `preprocess`, `build`, `check`, `clean`).

## Style guide

In the [divio](https://documentation.divio.com/) documentation system, our project lands halfway between a tutorial and a how-to guide.
Each section must be concise and focused on one topic.
Keep the language simple and the sentences short.

For each tool, we aim to provide:

1. a brief introduction with the relevant links
2. a small actionable demo presented as a code block

Every time a new resource is introduced, it should be accompanied with a link to the relevant GitHub repository or website, like so: [Revise.jl](https://github.com/timholy/Revise.jl).
Links to the package documentation are not necessary, unless they are meant to highlight a specific part.

Package names are written as normal text with the .jl extension, while functions or objects are written between backticks.
Multi-line scripts are given as executable code blocks, so that readers always see real, up-to-date output.

## Executable code blocks

Julia code blocks are executed when the site is built, and their output is rendered below the code like a REPL session.
The first character of the fence's info string selects the REPL mode, and the rest names the block:

```>example
x = 1
x + 1
```

- ` ```>name ` — julia mode: expressions are echoed and evaluated one by one, like in the REPL;
- ` ```?name ` — help mode;
- ` ```]name ` — pkg mode;
- ` ```;name ` — shell mode;
- ` ```!name ` — script mode: the code runs silently and is shown as a plain ` ```julia ` block, followed by its printed output. A `# hideall` comment hides the whole block, and a trailing `# hide` hides a single line.

All named fences on a page share one sandbox module, so later blocks can use variables defined in earlier ones.
Two conventions replace explicit setup code:

- If the page's directory contains a `Project.toml`, that environment is activated while the page runs. Add the packages your code blocks need there.
- Code blocks run inside a per-page scratch directory, so files are created and read with plain relative paths, exactly as a reader would type them.

## Admonitions

Callout boxes use the components defined in [`templates/components.html`](templates/components.html): `tldr`, `advanced`, and `vscode`.
The body is regular Markdown:

```markdown
{% <tldr> %}
A quick summary of the section.
{% </tldr> %}
```

Everything else is standard [Zola](https://www.getzola.org/documentation/):
the layout lives in `templates/`,
written as [Tera templates](https://www.getzola.org/documentation/templates/overview/),
styles live in `static/css/`,
and the site configuration in `zola.toml`.
