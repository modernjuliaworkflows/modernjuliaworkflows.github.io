# ZolaPreprocessor

Replays Xranklin's executable code fences and emits Zola-ready markdown with
ANSI-colored `<pre>` blocks (see `PLAN.md` at the repository root for the
migration context). Everything that is not an executable fence passes through
untouched.

The authoring syntax is unchanged from Xranklin:

- ` ```>name ` julia mode: expressions are echoed and evaluated one by one,
  like the REPL, with `ans` support and trailing-`;` result suppression;
- ` ```?name ` help mode (`REPL.helpmode`);
- ` ```]name ` pkg mode (`Pkg.REPLMode.pkgstr`);
- ` ```;name ` shell mode (`sh -c`);
- ` ```!name ` plain mode: code is included silently and shown as a regular
  ` ```julia ` block; `# hideall` hides the whole block, a trailing `# hide`
  hides single lines.

Named fences share one sandbox module per page. If the page's directory
contains a `Project.toml`, that environment is activated while the page runs.
Fences execute with the working directory set to a per-page scratch directory
under the (gitignored) `_workdir/`, so relative paths in fences never touch
the repository.

## Usage

```bash
julia --project=tools/ZolaPreprocessor tools/ZolaPreprocessor/main.jl <srcdir> <outdir>
```

The two arguments are the input and output directories: every `*.md` page
under `<srcdir>` is executed and written to the same relative path under
`<outdir>`. For this site that is `src` (the authored pages) and `content`
(the generated, gitignored directory that Zola builds), run from the
repository root with Julia 1.11 — the version the section environments are
resolved for:

```bash
julia --project=tools/ZolaPreprocessor tools/ZolaPreprocessor/main.jl src content
```

Options:

- `--only <page.md>` (repeatable) restricts the run to pages whose source
  path ends with the given path — fast iteration on a single page:

  ```bash
  julia --project=tools/ZolaPreprocessor tools/ZolaPreprocessor/main.jl src content --only src/writing/index.md
  ```

- `--workdir <dir>` sets the scratch directory fences run in
  (default: `./_workdir`).

The package follows the [Julia app](https://pkgdocs.julialang.org/v1/apps/)
conventions, so on Julia 1.12+ it can also be run without `main.jl`:

```bash
julia --project=tools/ZolaPreprocessor -m ZolaPreprocessor src content
```

Fence errors render REPL-style in the output (some pages rely on this) and
are summarized at the end of the run; they do not fail the build.
