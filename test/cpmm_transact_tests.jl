@testitem "transact! 1" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using ABMPredictionMarkets: compute_price
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: get_market
    using ABMPredictionMarkets: get_reserves
    using ABMPredictionMarkets: transact!
    using Agents
    using Test

    include("test_agent.jl")

    money = 100

    yes_reserves = 100
    no_reserves = 100
    config = (
        n_agents = 1,
        λ = 0.0,
        money,
        no_reserves = [yes_reserves],
        yes_reserves = [no_reserves],
        manipulate_time = 100,
    )

    model = initialize(CPMMAgent; config...)
    market = get_market(model)
    agent = model[1]

    midx = 1
    yes = true 
    belief = .55
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    n_shares = cost_to_shares(market, cost, midx, yes)
    order = AMMOrder(; id = agent.id, option = yes, cost, n_shares)
    transact!(order, market, model, midx)
    yes_reserves1, no_reserves1 = get_reserves(market, midx)

    @test agent.money ≈ 100 - cost
    @test agent.shares[1][1] == n_shares
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1


end

@testitem "transact! 2" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using ABMPredictionMarkets: compute_price
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: get_market
    using ABMPredictionMarkets: get_reserves
    using ABMPredictionMarkets: transact!
    using Agents
    using Test

    include("test_agent.jl")

    money = 100

    yes_reserves = 1000
    no_reserves = 1000
    config = (
        n_agents = 3,
        λ = 0.0,
        money,
        no_reserves = [yes_reserves],
        yes_reserves = [no_reserves],
        manipulate_time = 100,
    )

    model = initialize(CPMMAgent; config...)
    market = get_market(model)
    agent = model[1]

    midx = 1
    yes = false 
    belief = .40
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    n_shares = cost_to_shares(market, cost, midx, yes)
    order = AMMOrder(; id = agent.id, option = yes, cost, n_shares)
    transact!(order, market, model, midx)
    yes_reserves1, no_reserves1 = get_reserves(market, midx)

    @test cost ≈ 18.380873276792805
    @test n_shares ≈ 36.42998806196115
    @test agent.money ≈ 100 - cost
    @test agent.shares[1][2] == n_shares
    @test yes_reserves1 ≈ 1018.3808732767928
    @test no_reserves1 ≈ 981.9508852148317
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1
    @test compute_price(market, 1, true) ≈ 0.4908940134786863


    agent = model[3]
    midx = 1
    yes = true 
    belief = .60
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    n_shares = cost_to_shares(market, cost, midx, yes)
    order = AMMOrder(; id = agent.id, option = yes, cost, n_shares)
    transact!(order, market, model, midx)
    yes_reserves1, no_reserves1 = get_reserves(market, midx)

    @test cost ≈ 19.708876956223882
    @test n_shares ≈ 39.746762158361555
    @test agent.money ≈ 100 - cost
    @test agent.shares[1][1] == n_shares

    @test yes_reserves1 ≈ 998.3429880746552
    @test no_reserves1 ≈ 1001.6597621710556
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1
    @test compute_price(market, 1, true) ≈ 0.5008291923838587


    agent = model[2]
    midx = 1
    yes = false 
    belief = .50
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    n_shares = cost_to_shares(market, cost, midx, yes)
    order = AMMOrder(; id = agent.id, option = yes, cost, n_shares)
    transact!(order, market, model, midx)
    yes_reserves1, no_reserves1 = get_reserves(market, midx)

    @test cost ≈ 0.1505239724551987
    @test n_shares ≈ 0.30152526052706674
    @test agent.money ≈ 100 - cost
    @test agent.shares[1][2] == n_shares

    @test yes_reserves1 ≈ 998.4935120471104
    @test no_reserves1 ≈ 1001.5087608829838
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1
    @test compute_price(market, 1, true) ≈ 0.5007538113522881
end