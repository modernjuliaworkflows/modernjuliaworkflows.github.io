# Migration plan: Franklin/Xranklin → Zola

Status: **Commits 1–5 done — migration complete** · Branch: `ah/zola-experiment` ·
Target: Zola 0.23.3 (giallo-based highlighting, Tera 2 with components, content is
Tera-templated) · The first deploy via the GitHub Pages artifact flow is still
unexercised — after merge, spot-check the live site, `/feed.xml`, and the custom domain.

## Goal

Replace Xranklin with [Zola](https://www.getzola.org) as the static site generator while
**keeping the executed REPL output** (all four modes: `julia>`, `help?>`, `pkg>`, `shell>`)
and the existing authoring syntax for code fences. Syntax highlighting moves from
client-side highlight.js to Zola's build-time highlighter.

## Architecture after migration

```
src/**/*.md        authored pages, unchanged fence syntax (```>name, ```?name, ```]name, ```;name, ```!name)
   │
   │  tools/ZolaPreprocessor/  (Julia: executes fences, ANSI→HTML)
   ▼
content/**/*.md    generated, gitignored
   │
   │  zola build   (zola.toml, templates/ incl. components, static/, highlighting, feed.xml)
   ▼
public/            deployed via the GitHub Pages artifact flow (actions/deploy-pages)
```

Key properties:

- Authored markdown keeps the exact Xranklin *fence* syntax — contributor-facing syntax
  does not change. All other Xranklin machinery is replaced by idiomatic Julia/Zola
  conventions (decided 2026-08-13, see below).
- Everything Julia happens in one preprocessing step; Zola itself is a single binary with no plugins.
- Named fences share state page-wide (one sandbox module per page), as today.
- Each section keeps its own `Project.toml`/`Manifest.toml`, activated **by convention**:
  if the page's directory contains a `Project.toml`, the preprocessor activates it for
  the page (no `\activate{}` command).
- Fences run with the working directory set to a per-page scratch directory under the
  gitignored `_workdir/`, so plain relative paths (`Pkg.generate("MyPackage")`) replace
  the `sitepath(...)` shim, and rendered code is exactly what a reader would type.
- `\toc` becomes a `<!-- toc -->` marker in the authored markdown: shortcodes have no
  access to `page.toc` (getzola/zola#584), so the `with_toc` component
  (`templates/toc.html`) splices the list into the rendered content at the marker
  instead. The sidebar TOC is likewise rendered from `page.toc`.

## Accepted tradeoffs (decided)

1. **Header anchors change.** Franklin ids like `#help_mode_(?)` become Zola slugs like
   `#help-mode`. Inbound deep links from elsewhere will land at the top of the page
   (no 404). Internal links were fixed during migration. If this ever hurts, the
   preprocessor can stamp legacy ids later (`## Title {#old_id}`); explicitly deferred.
2. **`MyPackage` / `MyAwesomePackage` are no longer deployed.** They are generated during
   execution (PkgTemplates demo) and `Pkg.develop`ed by later fences, but nothing in the
   content links to the deployed copies. They are generated into the gitignored
   `_workdir/` used only during preprocessing.
3. **Unused Franklin machinery was dropped**, not ported: tag pages (`tag.html`,
   `{{taglist}}` — no page defined tags), demo hfuns in `utils.jl` (`hfun_bar`,
   `hfun_m1fill`, `lx_baz`).
4. **Per-page "Last modified" footer** became a build date (Tera `now()`).

---

## Docs (rest of Commit 5) — done 2026-08-14

- [x] Update `README.md`: now points to `CONTRIBUTING.md`, which carries the build
      instructions (Adrian's call): `julia --project=tools/ZolaPreprocessor
      -m ZolaPreprocessor serve` (preprocesses, runs `zola serve`, and watches
      `src/` for changes); Zola 0.23.3 and Julia 1.12 as prerequisites.
- [x] Update `CONTRIBUTING.md`: replace the Franklin documentation pointer with a short
      "executable code blocks" section documenting the (unchanged) fence syntax
      (```` ```>name ````, `?`, `]`, `;`, `!`, `# hideall`, `# hide`), the
      `{% <tldr> %}` components, the Project.toml-next-to-page and scratch-cwd
      conventions, and a link to Zola/Tera docs for templates.

**Review focus:** `rg -i "franklin|xranklin|highlight\.js" README.md CONTRIBUTING.md`
returns nothing (verified); the remaining repo-wide matches are intentional —
Franklin-parity comments, the carried-over `.franklin-content` CSS class and
`franklin.css` filename, and preprocessor test fixtures for legacy directives.

## Follow-ups (explicitly out of scope)

- Strict mode: fail CI on *unexpected* fence errors (`# allowerror` marker on intentional ones).
- Commit generated `content/` so docs-only PRs skip Julia entirely in CI.
- Legacy anchor id stamping, if broken inbound links turn out to matter.
