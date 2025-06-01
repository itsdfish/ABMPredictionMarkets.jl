@testitem "compute_optimal_purchase 1" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using Agents
    using Test

    include("test_agent.jl")

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    agent = CPMMAgent(;
        id = 1,
        judgments = [[0.55, 0.45]],
        money = 100.0,
        shares = [zeros(2)],
        λ = 0.0
    )

    midx = 1
    yes = true
    belief = agent.judgments[1][1]

    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    @test cost ≈ 6.252444561260544
end

@testitem "compute_optimal_purchase 2" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using Agents
    using Test

    include("test_agent.jl")

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    agent = CPMMAgent(;
        id = 1,
        judgments = [[0.6, 0.4]],
        money = 100.0,
        shares = [zeros(2)],
        λ = 0.0
    )

    midx = 1
    yes = false
    belief = agent.judgments[1][2]
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    @test cost ≈ 9.326580666278902
end

@testitem "compute_optimal_purchase 3" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using Agents
    using Test

    include("test_agent.jl")

    yes_reserves = 100
    no_reserves = 100
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    agent = CPMMAgent(;
        id = 1,
        judgments = [[0.5, 0.5]],
        money = 100.0,
        shares = [zeros(2)],
        λ = 0.0
    )

    midx = 1
    yes = false
    belief = agent.judgments[1][2]
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    @test cost ≈ 0.0
end

@testitem "compute_optimal_purchase 4" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using Agents
    using Test

    include("test_agent.jl")

    yes_reserves = 100
    no_reserves = 100
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    money = 100
    agent = CPMMAgent(;
        id = 1,
        judgments = [[1, 0]],
        money,
        shares = [zeros(2)],
        λ = 0.0
    )

    midx = 1
    yes = true
    belief = agent.judgments[1][1]
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    @test cost ≈ money
end

@testitem "compute_optimal_purchase 4" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using Agents
    using Test

    include("test_agent.jl")

    yes_reserves = 100
    no_reserves = 100
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    money = 100
    agent = CPMMAgent(;
        id = 1,
        judgments = [[1, 0]],
        money,
        shares = [zeros(2)],
        λ = 0.0
    )

    midx = 1
    yes = true
    belief = agent.judgments[1][1]
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    @test cost ≈ money
end

@testitem "compute_optimal_purchase 5" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_optimal_purchase
    using Agents
    using Test

    include("test_agent.jl")

    yes_reserves = 100
    no_reserves = 100
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    money = 100
    agent = CPMMAgent(;
        id = 1,
        judgments = [[1, 0]],
        money,
        shares = [zeros(2)],
        λ = 0.0
    )

    midx = 1
    yes = false
    belief = agent.judgments[1][2]
    cost = compute_optimal_purchase(agent, market, belief, midx, yes)
    @test cost ≈ 100
end
