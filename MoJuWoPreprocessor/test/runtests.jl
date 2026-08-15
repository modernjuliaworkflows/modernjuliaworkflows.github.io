using IOCapture: IOCapture
using Test
using MoJuWoPreprocessor
using MoJuWoPreprocessor: EXEC_FENCE_RE, FenceSyntaxError

include("common.jl")

# Run the CLI entry point with output captured, returning its exit code.
cli(args...) = IOCapture.capture(() -> MoJuWoPreprocessor.main(collect(String, args))).value

@testset "MoJuWoPreprocessor" begin
    include("linting.jl")

    @testset "executable fence regex" begin
        for line in (
                "```>repl-example", "```>\$-example", "```?help", "```]pkg-example",
                "```;sh", "```!", "```>", "```!name_with_underscore",
                "```>err allow-error", "```! allow-error",
            )
            @test match(EXEC_FENCE_RE, line) !== nothing
        end
        for line in (
                "```julia", "```julia-repl", "````markdown", "``` >x", "```bash",
                "```julia @distributed-sum", "text", "", "```>err allowerror",
            )
            @test match(EXEC_FENCE_RE, line) === nothing
        end
        @test match(EXEC_FENCE_RE, "```>err allow-error")[3] == "allow-error"
        @test match(EXEC_FENCE_RE, "```>err")[3] === nothing
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

        # The intentional error fence is marked `allow-error`: it renders
        # REPL-style (checked below) without being reported as a failure.
        @test isempty(failures)

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

    @testset "strict fence handling" begin
        tmp = mktempdir()
        render(text, rel) = process_page(text, rel; pagedir = tmp, workdir = tmp)

        # An unsanctioned error renders REPL-style and is reported...
        out, errors = render("```>boom\nsqrt(-1)\n```\n", "unsanctioned.md")
        @test occursin("DomainError", out)
        @test length(errors) == 1
        # ...and `allow-error` sanctions it.
        out, errors = @test_logs render(
            "```>boom allow-error\nsqrt(-1)\n```\n", "sanctioned.md"
        )
        @test occursin("DomainError", out)
        @test isempty(errors)
        # A stale `allow-error` mark warns so it cannot linger unnoticed.
        _, errors = @test_logs (:warn, r"did not error") render(
            "```>fine allow-error\n1 + 1\n```\n", "stale.md"
        )
        @test isempty(errors)

        # An error-level log message without a throw
        # (Base logs one when a package extension fails to load)
        # is reported like a thrown error...
        out, errors = render("```>logs\n@error \"boom\"\n```\n", "logged.md")
        @test occursin("boom", out)
        @test length(errors) == 1
        @test occursin("error-level log: boom", errors[1].message)
        # ...in plain mode too...
        _, errors = render("```!logs\n@error \"boom\"\n```\n", "logged-plain.md")
        @test length(errors) == 1
        # ...and `allow-error` sanctions it like a thrown error.
        _, errors = @test_logs render(
            "```>logs allow-error\n@error \"boom\"\n```\n", "logged-ok.md"
        )
        @test isempty(errors)
        # Warnings stay below the bar.
        _, errors = render("```>warns\n@warn \"just noise\"\n```\n", "warned.md")
        @test isempty(errors)

        # Structurally broken fences abort the page: unclosed executable
        # fences, unclosed plain fences, and executable fences with trailing
        # junk (here a misspelled flag).
        @test_throws FenceSyntaxError render("```>unclosed\n1 + 1\n", "u1.md")
        @test_throws FenceSyntaxError render("```julia\nunclosed\n", "u2.md")
        @test_throws FenceSyntaxError render("```>x allow-errors\n1\n```\n", "u3.md")
        err = try
            render("text\n\n```>oops\n1 + 1\n", "location.md")
        catch e
            e
        end
        @test err isa FenceSyntaxError
        @test occursin("location.md:3", sprint(showerror, err))

        # The CLI turns both kinds of brokenness into exit code 1.
        cd(mktempdir()) do
            mkpath("s")
            write("s/page.md", "```>ok\n1 + 1\n```\n")
            @test cli("preprocess", "s", "out") == 0
            write("s/page.md", "```>bad\nsqrt(-1)\n```\n")
            @test cli("preprocess", "s", "out") == 1
            write("s/page.md", "```>bad\n1 + 1\n")
            @test cli("preprocess", "s", "out") == 1
        end
    end
end
