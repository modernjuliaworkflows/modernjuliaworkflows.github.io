# Static analysis: package hygiene (Aqua), import hygiene (ExplicitImports),
# and type-level error detection (JET).
using Aqua
using ExplicitImports
using JET
using Test
using MoJuWoPreprocessor

@testset "linting" begin
    @testset "Aqua" begin
        Aqua.test_all(MoJuWoPreprocessor)
    end
    @testset "ExplicitImports" begin
        @test check_no_implicit_imports(MoJuWoPreprocessor) === nothing
        @test check_no_stale_explicit_imports(MoJuWoPreprocessor) === nothing
        @test check_all_explicit_imports_via_owners(MoJuWoPreprocessor) === nothing
        @test check_all_qualified_accesses_via_owners(MoJuWoPreprocessor) === nothing
        @test check_no_self_qualified_accesses(MoJuWoPreprocessor) === nothing
    end
    @testset "JET" begin
        JET.test_package(MoJuWoPreprocessor; target_modules = (MoJuWoPreprocessor,))
    end
end
