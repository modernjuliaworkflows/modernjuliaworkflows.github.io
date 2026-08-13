# CLI: walk the source tree, process every markdown page, mirror the result
# into the output directory, and summarize fence errors at the end.

"""
    process_tree(srcdir, outdir; workdir, only = String[]) -> failures

Process every `*.md` under `srcdir` (in sorted order, one sandbox module
each) into the same relative path under `outdir`. `only` restricts the run
to pages whose source path ends with one of the given paths. Returns a
`Dict` mapping page paths to their fence errors; fence errors do not abort
the build.
"""
function process_tree(srcdir::AbstractString, outdir::AbstractString;
                      workdir::AbstractString = joinpath(pwd(), "_workdir"),
                      only::Vector{String} = String[])
    pages = String[]
    for (root, _dirs, files) in walkdir(srcdir), f in files
        endswith(f, ".md") && push!(pages, relpath(joinpath(root, f), srcdir))
    end
    sort!(pages)
    if !isempty(only)
        wanted = normpath.(only)
        pages = [p for p in pages if
                 any(w -> endswith(normpath(joinpath(srcdir, p)), w), wanted)]
        isempty(pages) && error("--only matched no pages: ", join(only, ", "))
    end
    mkpath(workdir)
    failures = Dict{String,Vector{FenceError}}()
    # Keep Pkg from precompiling mid-page; CI precompiles the environments up
    # front and locally it only causes noise in the captured fence output.
    withenv("JULIA_PKG_PRECOMPILE_AUTO" => "0") do
        for rel in pages
            src = joinpath(srcdir, rel)
            @info "preprocess: $rel"
            output, errors = process_page(read(src, String), rel;
                                          pagedir = dirname(abspath(src)),
                                          workdir = workdir)
            dst = joinpath(outdir, rel)
            mkpath(dirname(dst))
            write(dst, output)
            isempty(errors) || (failures[rel] = errors)
        end
    end
    for (rel, errors) in sort!(collect(failures); by = first)
        for e in errors
            @warn "fence errored (rendered REPL-style)" page = rel fence = e.label e.message
        end
    end
    return failures
end

const USAGE = """
usage: julia --project=tools/ZolaPreprocessor tools/ZolaPreprocessor/main.jl <srcdir> <outdir>
           [--only <page.md>]... [--workdir <dir>]

See tools/ZolaPreprocessor/README.md for details."""

# Entry point following the Julia app conventions
# (https://pkgdocs.julialang.org/v1/apps/): on Julia 1.12+ this runs via
# `julia -m ZolaPreprocessor`; on 1.11 use main.jl. Deliberately not exported —
# an exported `@main` would also run after `Pkg.test`, with an empty ARGS.
function (@main)(args::Vector{String})
    positional = String[]
    only = String[]
    workdir = joinpath(pwd(), "_workdir")
    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--only" && i < length(args)
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
    if length(positional) != 2
        println(stderr, USAGE)
        return 2
    end
    process_tree(positional[1], positional[2]; workdir = String(workdir), only = only)
    return 0
end
