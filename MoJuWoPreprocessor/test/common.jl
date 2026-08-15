using MoJuWoPreprocessor

# Render the fixture tree into a temp directory and normalize machine-specific
# paths so the result is comparable across machines.
function render_fixture()
    tmp = mktempdir()
    srcdir = joinpath(tmp, "src")
    outdir = joinpath(tmp, "content")
    cp(joinpath(@__DIR__, "fixtures", "src"), srcdir)
    failures = process_tree(srcdir, outdir; workdir = joinpath(tmp, "_workdir"))
    got = read(joinpath(outdir, "page", "index.md"), String)
    for p in unique([realpath(tmp), tmp])
        got = replace(got, p => "<TMPDIR>")
    end
    return got, failures
end
