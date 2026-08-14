using IOCapture: IOCapture
using Test
using MoJuWoPreprocessor
using MoJuWoPreprocessor: EXEC_FENCE_RE

include("common.jl")

# Run the CLI entry point with output captured, returning its exit code.
cli(args...) = IOCapture.capture(() -> MoJuWoPreprocessor.main(collect(String, args))).value

@testset "MoJuWoPreprocessor" begin
    include("linting.jl")

    @testset "executable fence regex" begin
        for line in ("```>repl-example", "```>\$-example", "```?help", "```]pkg-example",
                     "```;sh", "```!", "```>", "```!name_with_underscore")
            @test match(EXEC_FENCE_RE, line) !== nothing
        end
        for line in ("```julia", "```julia-repl", "````markdown", "``` >x", "```bash",
                     "```julia @distributed-sum", "text", "")
            @test match(EXEC_FENCE_RE, line) === nothing
        end
    end

    @testset "CLI dispatch" begin
        @test cli("-h") == 0
        @test cli() == 2
        @test cli("frobnicate") == 2
        @test cli("--bogus") == 2
        @test cli("preprocess", "src-only") == 2
        @test cli("build", "unexpected") == 2
        @test cli("preprocess", "a", "b", "--", "--port", "1112") == 2
        cd(mktempdir()) do
            # No zola.toml here, so the Zola-backed commands bail out early.
            @test cli("check") == 2
            mkpath("content"); mkpath("public"); mkpath("_workdir")
            @test cli("clean") == 0
            @test !isdir("content") && !isdir("public") && !isdir("_workdir")
        end
    end

    # Reference test: render the fixture page (which exercises every fence
    # mode) and require the output to be identical to the committed expected
    # output. After an intentional behavior change, regenerate the expected
    # output with update_references.jl and review the diff.
    @testset "fixture page matches reference output" begin
        got, failures = render_fixture()
        want = read(joinpath(@__DIR__, "references", "page.md"), String)
        if got != want
            actualfile = joinpath(@__DIR__, "references", "page.actual.md")
            write(actualfile, got)
            @info "reference mismatch, actual output saved for diffing" actualfile
        end
        @test got == want

        # The intentional error fence is recorded but does not abort the run.
        @test haskey(failures, "page/index.md")
        @test any(e -> occursin("DomainError", e.message), failures["page/index.md"])

        # Targeted checks, readable without diffing the reference output.
        @test occursin("<span class=\"sgr32\"><span class=\"sgr1\">julia&gt;</span></span> x = 21", got)
        # Emitted blocks are fenced off from Tera's content templating: fence
        # output could print `{{`/`{%`/`{#`, which would otherwise be parsed.
        @test occursin("{% raw %}\n<pre", got)
        @test count("{% raw %}", got) == count("{% endraw %}", got) == count("<pre", got)
        @test occursin("ERROR: </span></span>DomainError with -1.0", got)
        @test occursin("(page) pkg&gt;", got)               # environment-aware pkg prompt
        @test occursin("hello from the shell", got)
        @test occursin("greet(name)", got)                  # help mode found the docstring
        @test occursin("scratch", got)                      # shell/julia share the page cwd
        @test !occursin("hidden_value", got)                # `#hideall`
        @test !occursin("hidden_setup = 1", got)            # trailing `# hide`
        @test occursin("visible_line = hidden_setup + 1;", got)  # ... but it executed
        @test !occursin("\\toc", got)                       # legacy directives dropped
        @test !occursin("\\activate", got)
        @test occursin("\\tldr{", got)                      # other content untouched
        @test occursin("```julia\nunexecuted() = \"not run\"\n```", got)
        @test occursin("inner() = 1", got)                  # nested fence left intact
    end
end
