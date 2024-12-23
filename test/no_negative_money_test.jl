@testitem "1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using Test

    include("test_agent.jl")

    model = initialize(
        TestAgent;
        n_agents = 100,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 3,
        n_markets = 5
    )
    run!(model, 100)
    money = map(a -> a.money, allagents(model))
    @test minimum(money) ≥ 0
end
