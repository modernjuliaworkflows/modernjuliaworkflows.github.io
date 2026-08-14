# CLI: `preprocess` walks the source tree, processes every markdown page,
# mirrors the result into the output directory, and summarizes fence errors
# at the end. `serve`/`build`/`check` preprocess and then drive Zola;
# `serve` additionally watches the source pages and re-preprocesses on change.

"""
    process_tree(srcdir, outdir; workdir, only = String[]) -> failures

Process every `*.md` under `srcdir` (in sorted order, one sandbox module
each) into the same relative path under `outdir`. `only` restricts the run
to pages whose source path ends with one of the given paths. Returns a
`Dict` mapping page paths to their fence errors; fence errors do not abort
the build.
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
    start = time()
    # Keep Pkg from precompiling mid-page; CI precompiles the environments up
    # front and locally it only causes noise in the captured fence output.
    withenv("JULIA_PKG_PRECOMPILE_AUTO" => "0") do
        for rel in pages
            src = joinpath(srcdir, rel)
            @info "preprocess: $rel"
            output, errors = process_page(
                read(src, String), rel;
                pagedir = dirname(abspath(src)),
                workdir = workdir
            )
            dst = joinpath(outdir, rel)
            mkpath(dirname(dst))
            write(dst, output)
            isempty(errors) || (failures[rel] = errors)
        end
    end
    n = length(pages)
    @info "preprocessed Julia code blocks in $(round(time() - start; digits = 1))s"
    for (rel, errors) in sort!(collect(failures); by = first)
        for e in errors
            @warn "fence errored (rendered REPL-style)" page = rel fence = e.label e.message
        end
    end
    return failures
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
updated output and live-reloads the browser. Runs until `zola serve` exits
(propagating its exit code) or Ctrl-C stops both processes.
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
    end
    return interrupted ? 0 : zola.exitcode
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
        process_tree(positional[1], positional[2]; workdir, only)
        return 0
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
    command == "serve" && return serve("src", "content"; workdir, only, zola_args)
    process_tree("src", "content"; workdir, only)
    return success(run(ignorestatus(`zola $command $zola_args`))) ? 0 : 1
end
