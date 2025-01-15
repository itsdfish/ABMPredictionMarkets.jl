
@testitem "1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: bid
    using ABMPredictionMarkets: init
    using ABMPredictionMarkets: remove_orders!
    using Random
    using Test

    Random.seed!(233)

    include("test_agent.jl")

    n_markets = 4
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 3
    )

    remove_all!(model)

    shares = [[
        Order(; id = 1, yes = true, type = :share, price = 20),
        Order(; id = 1, yes = true, type = :share, price = 15)
    ]]

    agent = add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 45,
        bid_reserve = 55,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :bid, price = 55),
        Order(; id = 1, yes = true, type = :ask, price = 45),
        Order(; id = 2, yes = true, type = :bid, price = 40)
    ]

    remove_orders!(agent, model, bidx)

    @test model.order_books[bidx] == [Order(; id = 2, yes = true, type = :bid, price = 40)]
    @test agent.money == 100
    @test agent.bid_reserve == 0
end
