# CLI: `preprocess` walks the source tree, processes every markdown page,
# mirrors the result into the output directory, and summarizes fence errors
# at the end. `serve`/`build`/`check` preprocess and then drive Zola;
# `serve` additionally watches the source pages and re-preprocesses on change,
# and `build` finishes by indexing the rendered site for search.

# Each page executes on its own persistent worker process, so nothing —
# loaded packages, extension triggers, redefined methods, global state —
# leaks between pages. Keyed by the page's absolute source path (not its
# relative path, which distinct trees like the site and the test fixtures
# could collide on).
const PAGE_WORKERS = Dict{String, Malt.Worker}()

# The worker's load path is a static environment stack, fixed at spawn:
# the page environment first (only if the page directory declares one),
# then the preprocessor's own environment so the worker can load
# MoJuWoPreprocessor, then the standard library. The page environment being
# the primary project also makes the `pkg>` prompt carry the page's name.
function spawn_page_worker(pagedir::AbstractString)
    # The leading `@` expands to nothing in the worker itself (no project is
    # ever explicitly activated there), but julia subprocesses spawned by
    # fence code inherit `JULIA_LOAD_PATH`, and without `@` their
    # `--project` would not be on their own load path (Aqua's
    # persistent_tasks check precompiles a wrapper package that way).
    stack = String["@"]
    isfile(joinpath(pagedir, "Project.toml")) && push!(stack, abspath(pagedir))
    host_project = Base.active_project()
    host_project === nothing || push!(stack, dirname(host_project))
    push!(stack, "@stdlib")
    w = Malt.Worker(;
        env = [
            "JULIA_LOAD_PATH=" * join(stack, Sys.iswindows() ? ";" : ":"),
            # Keep Pkg from precompiling mid-page; CI precompiles the
            # environments up front and locally it only causes noise in the
            # captured fence output.
            "JULIA_PKG_PRECOMPILE_AUTO=0",
        ]
    )
    Malt.remote_eval_wait(
        Main, w, quote
            import Pkg
            Pkg.instantiate(; io = devnull)
            import MoJuWoPreprocessor
        end
    )
    return w
end

function page_worker(src::AbstractString)
    w = get(PAGE_WORKERS, src, nothing)
    w !== nothing && Malt.isrunning(w) && return w
    return PAGE_WORKERS[src] = spawn_page_worker(dirname(src))
end

"""
    stop_page_workers()

Stop every page worker and empty the registry. Workers also die with the
host process; the explicit stop keeps command exits tidy.
"""
function stop_page_workers()
    for w in values(PAGE_WORKERS)
        Malt.isrunning(w) && Malt.stop(w)
    end
    empty!(PAGE_WORKERS)
    return nothing
end

# Worker-side entry point: Malt transports exceptions as printed messages,
# so a `FenceSyntaxError` must travel as a value for `process_tree` to
# rethrow it typed on the host side.
function worker_process_page(
        text::AbstractString, relpath::AbstractString,
        pagedir::AbstractString, workdir::AbstractString
    )
    try
        output, errors = process_page(text, relpath; pagedir, workdir)
        return (:ok, output, errors)
    catch err
        err isa FenceSyntaxError || rethrow()
        return (:fence_syntax_error, err.page, err.line, err.message)
    end
end

"""
    process_tree(srcdir, outdir; workdir, only = String[]) -> failures

Process every `*.md` under `srcdir` into the same relative path under
`outdir`, each page on its own persistent worker process (spawned lazily,
reused while it lives) so pages cannot leak loaded packages or global
state into each other. That isolation also lets all pages run
concurrently; outputs are written in sorted page order once every page
has finished. `only` restricts the run to pages whose source path ends
with one of the given paths. Returns a `Dict` mapping page paths to
their unsanctioned fence errors (errors in fences not marked
`allow-error`); the CLI build commands fail on those, `serve` only
reports them. A structurally broken fence throws a
[`FenceSyntaxError`](@ref) for the first broken page in sorted order.
"""
function process_tree(
        srcdir::AbstractString, outdir::AbstractString;
        workdir::AbstractString = joinpath(pwd(), "_workdir"),
        only::Vector{String} = String[]
    )
    pages = String[]
    for (root, _dirs, files) in walkdir(srcdir), f in files
        endswith(f, ".md") && push!(pages, relpath(joinpath(root, f), srcdir))
    end
    sort!(pages)
    if !isempty(only)
        wanted = normpath.(only)
        pages = [
            p for p in pages if
                any(w -> endswith(normpath(joinpath(srcdir, p)), w), wanted)
        ]
        isempty(pages) && error("--only matched no pages: ", join(only, ", "))
    end
    mkpath(workdir)
    failures = Dict{String, Vector{FenceError}}()
    @info "⏱️ Preprocessing Julia code blocks. \nThis may take a minute (subsequent evaluations will be faster)."
    start = time()
    # Worker isolation makes the pages independent, so they run
    # concurrently: each task only blocks on its worker's IO, the workers
    # do the actual work in parallel.
    results = Vector{Any}(undef, length(pages))
    @sync for (i, rel) in enumerate(pages)
        @async begin
            src = abspath(joinpath(srcdir, rel))
            # `remote_eval_fetch` rather than `remote_call_fetch`:
            # evaluation runs in the worker's latest world age, which the
            # entry point — imported after the worker's serve loop
            # started — requires.
            results[i] = Malt.remote_eval_fetch(
                Main, page_worker(src),
                :(
                    $worker_process_page(
                        $(read(src, String)), $rel, $(dirname(src)), $(abspath(workdir))
                    )
                )
            )
            @info "...preprocessed $rel"
        end
    end
    for (i, rel) in enumerate(pages)
        result = results[i]
        if first(result) === :fence_syntax_error
            _, page, line, message = result
            throw(FenceSyntaxError(page, line, message))
        end
        _, output, errors = result
        dst = joinpath(outdir, rel)
        mkpath(dirname(dst))
        write(dst, output)
        isempty(errors) || (failures[rel] = errors)
    end
    n = length(pages)
    @info "✅ Preprocessed Julia code blocks in $(round(time() - start; digits = 1))s"
    for (rel, errors) in sort!(collect(failures); by = first)
        for e in errors
            @error "fence errored" page = rel fence = e.label e.message
        end
    end
    return failures
end

# Strict pass for the build commands: a `FenceSyntaxError` aborts with a
# clean message and unsanctioned fence errors fail the run, both as exit
# code 1.
function preprocess_strict(
        srcdir::AbstractString, outdir::AbstractString;
        workdir::AbstractString, only::Vector{String}
    )
    failures = try
        process_tree(srcdir, outdir; workdir, only)
    catch err
        err isa FenceSyntaxError || rethrow()
        println(stderr, sprint(showerror, err))
        return 1
    end
    isempty(failures) && return 0
    n = sum(length, values(failures))
    println(
        stderr,
        "$n fence error(s); fix them or mark intentional error demos with `allow-error`"
    )
    return 1
end

"""
    page_mtimes(srcdir) -> Dict{String,Float64}

Map every `*.md` page under `srcdir` (as a path relative to it) to its mtime.
"""
function page_mtimes(srcdir::AbstractString)
    times = Dict{String, Float64}()
    for (root, _dirs, files) in walkdir(srcdir), f in files
        endswith(f, ".md") || continue
        path = joinpath(root, f)
        times[relpath(path, srcdir)] = mtime(path)
    end
    return times
end

"""
    serve(srcdir, outdir; workdir, only = String[], zola_args = String[]) -> exit code

Preprocess the tree, start `zola serve`, then poll the source pages and
re-preprocess any page whose mtime changes. Zola's own watcher sees the
updated output and live-reloads the browser. Page workers stay warm across
re-preprocesses, so saving a page re-runs it in seconds instead of a cold
start. Runs until `zola serve` exits (propagating its exit code) or Ctrl-C
stops both processes. Unlike the build commands, fence errors only get
reported here — a dev server should survive broken intermediate states.
"""
function serve(
        srcdir::AbstractString, outdir::AbstractString;
        workdir::AbstractString, only::Vector{String} = String[],
        zola_args::Vector{String} = String[], interval::Real = 0.5
    )
    # Snapshot before the initial pass so pages edited while it runs are
    # caught by the first poll rather than silently absorbed.
    mtimes = page_mtimes(srcdir)
    process_tree(srcdir, outdir; workdir, only)
    zola = run(pipeline(`zola serve $zola_args`; stdout, stderr); wait = false)
    @info "watching $srcdir; saving a page re-preprocesses it (Ctrl-C stops)"
    # Without this, SIGINT kills Julia before the finally can reap Zola.
    Base.exit_on_sigint(false)
    interrupted = false
    try
        while process_running(zola)
            sleep(interval)
            current = page_mtimes(srcdir)
            changed = sort!([page for (page, t) in current if get(mtimes, page, 0.0) != t])
            mtimes = current
            isempty(changed) && continue
            try
                process_tree(srcdir, outdir; workdir, only = changed)
            catch err
                # Keep the server alive: broken intermediate saves are normal.
                @error "re-preprocess failed" pages = changed exception = (err, catch_backtrace())
            end
        end
    catch err
        err isa InterruptException || rethrow()
        interrupted = true
    finally
        Base.exit_on_sigint(true)
        process_running(zola) && kill(zola)
        stop_page_workers()
    end
    return interrupted ? 0 : zola.exitcode
end

"""
    index_search() -> exit code

Build the Pagefind search bundle into `public/pagefind/` by crawling the
rendered site; `js/search.js` loads it for the full-text result tier.
`pagefind` is optional locally (CI installs a pinned version), so a missing
binary only warns: the site works without it, minus full-text search.
"""
function index_search()
    if isnothing(Sys.which("pagefind"))
        @warn "`pagefind` not found on PATH; skipping the search index (https://pagefind.app)"
        return 0
    end
    return success(run(ignorestatus(`pagefind --site public`))) ? 0 : 1
end

const USAGE = """
usage: julia --project=MoJuWoPreprocessor -m MoJuWoPreprocessor <command> [options]
       (on Julia 1.11, use `MoJuWoPreprocessor/main.jl` instead of `-m MoJuWoPreprocessor`)

commands:
  preprocess <srcdir> <outdir>   execute every markdown page under <srcdir>
                                 into the same relative path under <outdir>
  serve                          preprocess src/ into content/, run `zola serve`,
                                 and re-preprocess pages as they change
  build                          preprocess src/ into content/, then `zola build`
                                 and index the site for search with `pagefind`
  check                          preprocess src/ into content/, then `zola check`
  clean                          remove content/, public/ and the workdir

options:
  --only <page.md>   (repeatable) restrict preprocessing to pages whose source
                     path ends with the given path
  --workdir <dir>    scratch directory fences run in (default: ./_workdir)
  -- <args>...       pass everything after `--` to the Zola command,
                     e.g. `serve -- --port 1112 --open`

The Zola-backed commands must run from the repository root (next to zola.toml).
See MoJuWoPreprocessor/README.md for details."""

# Entry point following the Julia app conventions
# (https://pkgdocs.julialang.org/v1/apps/): on Julia 1.12+ this runs via
# `julia -m MoJuWoPreprocessor`; on 1.11 use main.jl. Deliberately not exported —
# an exported `@main` would also run after `Pkg.test`, with an empty ARGS.
function (@main)(args::Vector{String})
    positional = String[]
    only = String[]
    zola_args = String[]
    workdir = joinpath(pwd(), "_workdir")
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--"
            append!(zola_args, args[(i + 1):end])
            break
        elseif a == "--only" && i < length(args)
            only = push!(only, args[i += 1])
        elseif startswith(a, "--only=")
            push!(only, chopprefix(a, "--only="))
        elseif a == "--workdir" && i < length(args)
            workdir = args[i += 1]
        elseif startswith(a, "--workdir=")
            workdir = chopprefix(a, "--workdir=")
        elseif a in ("-h", "--help")
            println(USAGE)
            return 0
        elseif startswith(a, "-")
            println(stderr, "unknown option: $a\n\n$USAGE")
            return 2
        else
            push!(positional, a)
        end
        i += 1
    end
    workdir = String(workdir)
    if isempty(positional)
        println(stderr, USAGE)
        return 2
    end
    command = popfirst!(positional)
    if command in ("preprocess", "clean") && !isempty(zola_args)
        println(stderr, "`$command` does not take `--` arguments\n\n$USAGE")
        return 2
    end
    if command == "preprocess"
        if length(positional) != 2
            println(stderr, "`preprocess` expects <srcdir> <outdir>\n\n$USAGE")
            return 2
        end
        code = preprocess_strict(positional[1], positional[2]; workdir, only)
        stop_page_workers()
        return code
    end
    if !(command in ("serve", "build", "check", "clean"))
        println(stderr, "unknown command: $command\n\n$USAGE")
        return 2
    end
    if !isempty(positional)
        println(stderr, "unexpected argument for `$command`: $(positional[1])\n\n$USAGE")
        return 2
    end
    if command == "clean"
        for dir in ("content", "public", workdir)
            rm(dir; force = true, recursive = true)
        end
        return 0
    end
    if !isfile("zola.toml")
        println(stderr, "`$command` must run from the repository root (no zola.toml in $(pwd()))")
        return 2
    end
    if isnothing(Sys.which("zola"))
        println(stderr, "`zola` not found on PATH; see https://www.getzola.org/documentation/getting-started/installation/")
        return 2
    end
    if command == "serve"
        try
            return serve("src", "content"; workdir, only, zola_args)
        catch err
            # Only the initial pass throws; while watching, syntax errors in
            # intermediate saves are caught and reported without stopping.
            err isa FenceSyntaxError || rethrow()
            println(stderr, sprint(showerror, err))
            return 1
        end
    end
    code = preprocess_strict("src", "content"; workdir, only)
    stop_page_workers()
    code == 0 || return code
    success(run(ignorestatus(`zola $command $zola_args`))) || return 1
    return command == "build" ? index_search() : 0
end
