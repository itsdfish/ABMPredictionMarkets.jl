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
        judgments = [45, 25, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        max_quantity = 1,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, quantity = 1, price = 20),
        Order(; id = 2, yes = false, type = :ask, quantity = 1, price = 90)
    ]

    remove_orders!(agent, model, bidx)
    proposal = ask(agent, model, bidx)

    @test proposal.price ≥ 46 && proposal.price ≤ 48
    @test proposal.yes
    @test proposal.id == 1
    @test proposal.type == :ask
    @test model.order_books[bidx] ==
          [Order(; id = 2, yes = false, type = :ask, quantity = 1, price = 90)]
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
        judgments = [45, 25, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        max_quantity = 1,
        shares = shares
    )

    model.order_books[bidx] = [
        Order(; id = 1, yes = true, type = :ask, quantity = 1, price = 20),
        Order(; id = 2, yes = true, type = :bid, quantity = 1, price = 46)
    ]

    remove_orders!(agent, model, bidx)
    proposal = ask(agent, model, bidx)

    @test proposal.price[bidx] == 46
    @test proposal.yes
    @test proposal.id == 1
    @test proposal.type == :ask
    @test model.order_books[bidx] ==
          [Order(; id = 2, yes = true, type = :bid, quantity = 1, price = 46)]
    @test agent.shares == shares
end

@testitem "ask sanity test" begin
    using Agents
    using ABMPredictionMarkets: get_market_info
    using ABMPredictionMarkets: agent_step!
    using ABMPredictionMarkets: sample_ask
    using Test

    include("test_agent.jl")

    n_agents = 1000
    n_reps = 10
    model = initialize(
        TestAgent;
        n_agents = 100,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 3
    )

    for _ ∈ 1:n_reps
        for id ∈ Agents.schedule(model)
            agent = model[id]
            agent_step!(agent, model)
            for (i, shares) ∈ enumerate(agent.shares)
                for s ∈ shares
                    judgment = s.yes ? agent.judgments[i] : (100 - agent.judgments[i])
                    @test s.price < judgment
                end
            end
        end
    end
end
