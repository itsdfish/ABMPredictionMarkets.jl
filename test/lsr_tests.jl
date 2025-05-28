@testitem "compute_prices 1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_prices
    using Test

    elasticity = fill(100.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    prices = compute_prices(market, 1)

    @test prices ≈ [0.50, 0.50]
end

@testitem "compute_prices 2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_prices
    using Test

    elasticity = fill(100.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    market.n_shares[1] = [10, 0]
    prices = compute_prices(market, 1)

    @test prices ≈ [0.5250, 0.4750] atol = 1e-3
end

@testitem "compute_prices 3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_prices
    using Test

    elasticity = fill(Inf, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    market.n_shares[1] = [10, 0]
    prices = compute_prices(market, 1)

    @test prices ≈ [0.50, 0.50] atol = 1e-3
end

@testitem "shares_to_cost 1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    n_buy = 1
    price = 0.50
    elasticity = fill(100.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    market.n_shares[1] = [10, 0]
    cost = shares_to_cost(market, price, n_buy, 1)

    @test cost ≈ -0.5012 atol = 1e-3
end

@testitem "shares_to_cost 2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    n_buy = -1
    price = 0.50
    elasticity = fill(100.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    market.n_shares[1] = [10, 0]
    cost = shares_to_cost(market, price, n_buy, 1)

    @test cost ≈ 0.4988 atol = 1e-3
end

@testitem "shares_to_cost 3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    n_buy = -1
    price = 0.50
    elasticity = fill(0.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    market.n_shares[1] = [10, 0]
    cost = shares_to_cost(market, price, n_buy, 1)

    @test cost ≈ 0
end

@testitem "buy sell" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: compute_prices
    using Test

    money = 100
    price = 0.50
    elasticity = fill(100.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    prices = compute_prices(market, 1)

    idx = 1
    n_buy = 100
    cost = shares_to_cost(market, prices[idx], n_buy, 1)
    market.n_shares[1][idx] += n_buy
    money += ceil(cost * 100) / 100
    prices = compute_prices(market, 1)

    idx = 1
    n_buy = -100
    cost = shares_to_cost(market, prices[idx], n_buy, 1)
    market.n_shares[1][idx] += n_buy
    money += floor(cost * 100) / 100
    prices = compute_prices(market, 1)

    @test money ≈ 100
    @test prices ≈ [0.50, 0.50]
end

@testitem "buy yes, buy no" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: compute_prices
    using Test

    money = 100
    price = 0.50
    elasticity = fill(100.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)
    prices = compute_prices(market, 1)

    idx = 1
    n_buy = 100
    cost = shares_to_cost(market, prices[idx], n_buy, 1)
    market.n_shares[1][idx] += n_buy
    money += ceil(cost * 100) / 100
    prices = compute_prices(market, 1)

    idx = 2
    n_buy = 100
    cost = shares_to_cost(market, prices[idx], n_buy, 1)
    market.n_shares[1][idx] += n_buy
    money += floor(cost * 100) / 100
    prices = compute_prices(market, 1)

    @test money ≈ 0
    @test prices ≈ [0.50, 0.50]
end

@testitem "cost share conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    price = 0.25
    cost = -100
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    shares = cost_to_shares(market, cost, price, 1)
    cost1 = shares_to_cost(market, price, shares, 1)

    @test cost ≈ cost1
end

@testitem "share cost conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    price = 0.25
    shares = 20
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    cost = shares_to_cost(market, price, shares, 1)

    shares1 = cost_to_shares(market, cost, price, 1)
    @test shares ≈ shares1
end

@testitem "cost to price conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_price
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    price = 0.30
    cost = 20
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    shares = cost_to_shares(market, cost, price, 1)
    new_price = shares_to_price(market, price, shares, 1)
    cost1 = price_to_cost(market, new_price, price, 1)

    @test cost ≈ cost1
end

@testitem "price to cost conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_price
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    price = 0.30
    cost = 20
    shares = 25
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    new_price = shares_to_price(market, price, shares, 1)
    cost = price_to_cost(market, new_price, price, 1)
    shares1 = cost_to_shares(market, cost, price, 1)

    @test shares ≈ shares1
end

@testitem "price to shares conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: price_to_shares
    using ABMPredictionMarkets: shares_to_price
    using Test

    price = 0.30
    new_price = 0.35
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    shares = price_to_shares(market, new_price, price, 1)
    new_price1 = shares_to_price(market, price, shares, 1)

    @test new_price ≈ new_price1
end

@testitem "shares to price conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: price_to_shares
    using ABMPredictionMarkets: shares_to_price
    using Test

    price = 0.30
    shares = 16
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    new_price = shares_to_price(market, price, shares, 1)
    shares1 = price_to_shares(market, new_price, price, 1)

    @test shares ≈ shares1
end

@testitem "set elasticity" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: set_elasticity
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: compute_prices
    using Test

    money = 1000
    n = 2
    upper_price = 0.98
    n_shares = fill(0.0, 2)
    elasticity = fill(300.0, 2)
    n_options = fill(2, 2)
    market = LSR(; elasticity, n_options)

    b = set_elasticity(money, n, upper_price)
    market.elasticity[1] = b
    market.n_shares[1][1] = cost_to_shares(market, -money, 0.50, 1)
    prices = compute_prices(market, 1)

    @test prices[1] ≈ upper_price
end

@testitem "run LSR" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: set_elasticity
    using ABMPredictionMarkets: compute_prices
    using Distributions
    using Random
    using Test

    Random.seed!(84)

    include("test_agent.jl")

    μ = [0.20, 0.25, 0.10, 0.45]

    model = initialize(
        LSRAgent;
        n_agents = 1000,
        μ,
        η = 1000,
        money = 100
    )
    run!(model, 10)

    market = abmproperties(model)
    prices = compute_prices(market, 1)

    @test μ ≈ prices atol = 0.020
end
