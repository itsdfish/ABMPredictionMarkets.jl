@testitem "data length tests" begin
    using ABMPredictionMarkets
    using Agents
    using Statistics
    using Test

    include("test_agent.jl")

    n_days = 100
    n_agents = 100
    μ = [0.05, 0.25, 0.10, 0.60]
    n_markets = length(μ)
    model = initialize(
        TestAgent;
        n_agents,
        μ,
        η = 20.0,
        money = 10_000,
        δ = 3
    )

    run!(model, n_days)

    lengths = fill(n_agents * n_days, n_markets)
    @test length.(model.market_prices) == lengths
    @test length.(model.trade_made) == lengths
    @test length.(model.iteration_ids) == lengths
end
