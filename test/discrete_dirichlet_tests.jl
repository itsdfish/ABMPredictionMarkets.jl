@testitem "sum to 100" begin
    using Distributions
    using ABMPredictionMarkets: DiscreteDirichlet
    using Test

    for _ ∈ 1:1000
        θ = rand(Dirichlet([1, 1, 1, 1]))
        η = rand(Gamma(2, 1))
        dist = DiscreteDirichlet(θ, η)
        x = rand(dist)
        @test sum(x) == 100
    end
end
