# The main test in runtests.jl is a reference test: it renders the fixture
# page test/fixtures/src/page/index.md and requires the output to be identical
# to the committed expected output test/references/page.md. This script
# regenerates that expected output after an intentional behavior change:
#
#     julia +1.12 --project=MoJuWoPreprocessor MoJuWoPreprocessor/test/update_references.jl
#
# Review the diff before committing — every hunk is a deliberate change in
# what the preprocessor emits. Use Julia 1.12: other versions may format
# docstrings or errors slightly differently.
using MoJuWoPreprocessor
include(joinpath(@__DIR__, "common.jl"))

got, _ = render_fixture()
reference = joinpath(@__DIR__, "references", "page.md")
mkpath(dirname(reference))
write(reference, got)
println("wrote ", reference)
