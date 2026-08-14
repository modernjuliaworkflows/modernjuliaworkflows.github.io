# ZolaPreprocessor

Replays Xranklin's executable code fences and emits Zola-ready markdown with ANSI-colored `<pre>` blocks. 
Everything that is not an executable fence passes through untouched.

The authoring syntax is unchanged from Xranklin:

- ` ```>name ` julia mode: expressions are echoed and evaluated one by one,
  like the REPL, with `ans` support and trailing-`;` result suppression;
- ` ```?name ` help mode (`REPL.helpmode`);
- ` ```]name ` pkg mode (`Pkg.REPLMode.pkgstr`);
- ` ```;name ` shell mode (`sh -c`);
- ` ```!name ` plain mode: code is included silently and shown as a regular
  ` ```julia ` block; `# hideall` hides the whole block, a trailing `# hide`
  hides single lines.

Named fences share one sandbox module per page. 
If the page's directory contains a `Project.toml`, that environment is activated while the page runs.
Fences execute with the working directory set to a per-page scratch directory under the (gitignored) `_workdir/`, 
so relative paths in fences never touch the repository.

## Usage

The package follows the [Julia app](https://pkgdocs.julialang.org/v1/apps/) conventions; 
run it from the repository root:

```bash
julia --project=tools/ZolaPreprocessor -m ZolaPreprocessor <command>
```

(On Julia 1.11, which lacks `-m`, substitute `tools/ZolaPreprocessor/main.jl` for `-m ZolaPreprocessor`.)

Commands:

- `preprocess <srcdir> <outdir>` executes every `*.md` page under `<srcdir>`
  and writes it to the same relative path under `<outdir>`. 
  For this site that is `src` (the authored pages) and `content` 
  (the generated, gitignored directory that Zola builds).
- `serve` preprocesses `src/` into `content/`, starts `zola serve`, 
  and then watches the pages under `src/`: 
  saving one re-preprocesses just that page, which Zola's own watcher picks up for live reload. 
  Because pages execute in-process, packages loaded on the first pass stay loaded, 
  so re-processing a page takes seconds instead of a cold start. 
  Note that warm re-runs share package-level global state with earlier runs; 
  the cold build remains the source of truth.
- `build` / `check` preprocess `src/` into `content/`, then run the corresponding Zola command.
- `clean` removes `content/`, `public/` and the workdir.

Options:

- `--only <page.md>` (repeatable) restricts preprocessing to pages whose
  source path ends with the given path — fast iteration on a single page:

  ```bash
  julia --project=tools/ZolaPreprocessor -m ZolaPreprocessor preprocess src content --only src/writing/index.md
  ```

- `--workdir <dir>` sets the scratch directory fences run in
  (default: `./_workdir`).
- Everything after `--` is passed to the Zola command, e.g.
  `serve -- --port 1112 --open`.

The Zola-backed commands (`serve`, `build`, `check`) expect `zola` on the
PATH and must run from the repository root (next to `zola.toml`). CI runs
`preprocess` and then calls `zola build`/`zola check` directly so the pages
are only executed once.

Fence errors render REPL-style in the output (some pages rely on this) and
are summarized at the end of the run; they do not fail the build.
