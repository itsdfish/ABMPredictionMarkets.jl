@testitem "1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask
    using ABMPredictionMarkets: init
    using ABMPredictionMarkets: remove_orders!
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
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
        money = 100,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, price = 20),
        Order(; id = 2, yes = false, type = :ask, price = 90)
    ]

    remove_orders!(agent, model, bidx)
    proposal = ask(agent, model, bidx)

    @test proposal.price[bidx] ≥ 21 && proposal.price[bidx] ≤ 23
    @test proposal.yes
    @test proposal.id == 1
    @test proposal.type == :ask
    @test model.order_books[bidx] == [Order(; id = 2, yes = false, type = :ask, price = 90)]
    @test agent.shares == shares
end

@testitem "2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask
    using ABMPredictionMarkets: init
    using ABMPredictionMarkets: remove_orders!
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
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
        money = 100,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, price = 20),
        Order(; id = 2, yes = true, type = :bid, price = 30)
    ]

    remove_orders!(agent, model, bidx)
    proposal = ask(agent, model, bidx)

    @test proposal.price[bidx] == 30
    @test proposal.yes
    @test proposal.id == 1
    @test proposal.type == :ask
    @test model.order_books[bidx] == [Order(; id = 2, yes = true, type = :bid, price = 30)]
    @test agent.shares == shares
end
