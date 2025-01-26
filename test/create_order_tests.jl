@testitem "ask" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: create_order
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1
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
        money = 0,
        bid_reserve = 0,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, quantity = 1, price = 20),
        Order(; id = 2, yes = false, type = :ask, quantity = 1, price = 10)
    ]

    for i ∈ 1:20
        proposal = create_order(agent, model, bidx)
        @test proposal.type == :ask
    end
end

@testitem "bid" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: create_order
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1
    )

    remove_all!(model)

    agent = add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    model.order_books[1] = [
        Order(; id = 1, yes = true, type = :ask, quantity = 1, price = 20),
        Order(; id = 2, yes = false, type = :ask, quantity = 1, price = 10)
    ]

    #for i ∈ 1:20
    proposal = create_order(agent, model, bidx)
    @test proposal.type == :bid
    @test agent.money == (100 - proposal.price)
    @test agent.bid_reserve == proposal.price
    #end
end
