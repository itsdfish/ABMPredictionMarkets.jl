@testitem "run multiagent" begin
    using Agents
    using ABMPredictionMarkets
    using Distributions
    using Random
    using Test

    Random.seed!(84)

    include("test_agent.jl")

    μ = [0.20, 0.25, 0.10, 0.45]

    model = initialize(
        Agent1,
        Agent2;
        n_agents = 1000,
        μ,
        η = 100.0,
        δ = 3,
        money = 1000
    )
    run!(model, 10)

    prices = summarize_by_iteration.(model.market_prices, model.iteration_ids)
    @test μ ≈ mean.(prices) atol = 0.015
end