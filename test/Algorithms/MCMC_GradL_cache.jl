using NeuralQuantum: MCMCGradientLEvaluationCache

function test_zero(sc::MCMCGradientLEvaluationCache)
    @testset "MCMCSREvaluationCache zero!" begin
        @test iszero(sc.Oave)
        @test iszero(sc.Eave)
        @test iszero(sc.EOave)
        @test iszero(sc.LLOave)
        @test iszero(sc.Zave)

        @test isempty(sc.Evalues)
    end
end

function random_data!(sc::MCMCGradientLEvaluationCache)
    [ rand!(el) for el=sc.Oave]
    sc.Eave = rand()
    [ rand!(el) for el=sc.EOave]
    [ rand!(el) for el=sc.LLOave]
    sc.Zave = rand()

    append!(sc.Evalues, rand(ComplexF64, 30))
end

function test_sum!(a::T, b::T, c::T) where T<:MCMCGradientLEvaluationCache
    @test all(a.Oave .+ b.Oave .≈ c.Oave)
    @test a.Eave + b.Eave ≈ c.Eave
    @test all(a.EOave .+ b.EOave .≈ c.EOave)
    @test all(a.LLOave .+ b.LLOave .≈ c.LLOave)
    @test a.Zave + b.Zave ≈ c.Zave

    @test any([vcat(a.Evalues, b.Evalues) ≈ c.Evalues,
               vcat(b.Evalues, a.Evalues) ≈ c.Evalues])
end
