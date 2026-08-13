# Static analysis: package hygiene (Aqua), import hygiene (ExplicitImports),
# and type-level error detection (JET).
using Aqua
using ExplicitImports
using JET
using Test
using ZolaPreprocessor

@testset "linting" begin
    @testset "Aqua" begin
        Aqua.test_all(ZolaPreprocessor)
    end
    @testset "ExplicitImports" begin
        @test check_no_implicit_imports(ZolaPreprocessor) === nothing
        @test check_no_stale_explicit_imports(ZolaPreprocessor) === nothing
        @test check_all_explicit_imports_via_owners(ZolaPreprocessor) === nothing
        @test check_all_qualified_accesses_via_owners(ZolaPreprocessor) === nothing
        @test check_no_self_qualified_accesses(ZolaPreprocessor) === nothing
    end
    @testset "JET" begin
        JET.test_package(ZolaPreprocessor; target_modules = (ZolaPreprocessor,))
    end
end
