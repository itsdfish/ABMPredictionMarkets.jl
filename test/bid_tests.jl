@testitem "1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: bid
    using ABMPredictionMarkets: init
    using ABMPredictionMarkets: remove_orders!
    using Random
    using Test
    Random.seed!(5870)

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
        Order(; id = 1, yes = true, type = :share, quantity = 1, price = 20),
        Order(; id = 1, yes = true, type = :share, quantity = 1, price = 15)
    ]]

    agent = add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, quantity = 1, price = 20),
        Order(; id = 2, yes = true, type = :ask, quantity = 1, price = 10)
    ]

    remove_orders!(agent, model, bidx)
    proposal = bid(agent, model, bidx)

    @test proposal.price[bidx] == 10
    @test proposal.yes
    @test proposal.id == 1
    @test proposal.type == :bid
    @test model.order_books[bidx] ==
          [Order(; id = 2, yes = true, type = :ask, quantity = 1, price = 10)]
    @test agent.shares == shares
    @test agent.money == 90
    @test agent.bid_reserve == 10
end

@testitem "2" begin
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
        Order(; id = 1, yes = true, type = :share, quantity = 1, price = 20),
        Order(; id = 1, yes = true, type = :share, quantity = 1, price = 15)
    ]]

    agent = add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, quantity = 1, price = 55),
        Order(; id = 2, yes = true, type = :ask, quantity = 1, price = 60)
    ]

    remove_orders!(agent, model, bidx)
    proposal = bid(agent, model, bidx)

    @test proposal.price[bidx] ≥ 45 && proposal.price[bidx] ≤ 49
    @test proposal.yes
    @test proposal.id == 1
    @test proposal.type == :bid
    @test model.order_books[bidx] ==
          [Order(; id = 2, yes = true, type = :ask, quantity = 1, price = 60)]
    @test agent.shares == shares
    @test agent.money == (100 - proposal.price[bidx])
    @test agent.bid_reserve == proposal.price[bidx]
end
