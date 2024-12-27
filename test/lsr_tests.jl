@testitem "compute_prices 1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_prices
    using Test

    b = 100
    n = fill(0, 2)
    money = 100
    maker = 0
    prices = compute_prices(n, b)

    @test prices ≈ [0.50, 0.50]
end

@testitem "compute_prices 2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_prices
    using Test

    b = 100
    n = [10, 0]
    money = 100
    maker = 0
    prices = compute_prices(n, b)

    @test prices ≈ [0.5250, 0.4750] atol = 1e-3
end

@testitem "compute_prices 3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: compute_prices
    using Test

    b = Inf
    n = [10, 0]
    money = 100
    maker = 0
    prices = compute_prices(n, b)

    @test prices ≈ [0.50, 0.50] atol = 1e-3
end

@testitem "shares_to_cost 1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    b = 100
    n_buy = 1
    price = 0.50

    cost = shares_to_cost(price, n_buy, b)

    @test cost ≈ -0.5012 atol = 1e-3
end

@testitem "shares_to_cost 2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    b = 100
    n_buy = -1
    price = 0.50

    cost = shares_to_cost(price, n_buy, b)

    @test cost ≈ 0.4988 atol = 1e-3
end

@testitem "shares_to_cost 3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    b = 0
    n_buy = -1
    price = 0.50

    cost = shares_to_cost(price, n_buy, b)

    @test cost ≈ 0
end

@testitem "buy  sell" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: compute_prices
    using Test

    b = 100
    n = fill(0, 2)
    money = 100
    prices = compute_prices(n, b)

    idx = 1
    n_buy = 100
    cost = shares_to_cost(prices[idx], n_buy, b)
    n[idx] += n_buy
    money += ceil(cost * 100) / 100
    prices = compute_prices(n, b)

    idx = 1
    n_buy = -100
    cost = shares_to_cost(prices[idx], n_buy, b)
    n[idx] += n_buy
    money += floor(cost * 100) / 100
    prices = compute_prices(n, b)

    @test money ≈ 100
    @test prices ≈ [0.50, 0.50]
end

@testitem "buy yes, buy no" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: compute_prices
    using Test

    b = 100
    n = fill(0, 2)
    money = 100
    prices = compute_prices(n, b)

    idx = 1
    n_buy = 100
    cost = shares_to_cost(prices[idx], n_buy, b)
    n[idx] += n_buy
    money += ceil(cost * 100) / 100
    prices = compute_prices(n, b)

    idx = 2
    n_buy = 100
    cost = shares_to_cost(prices[idx], n_buy, b)
    n[idx] += n_buy
    money += floor(cost * 100) / 100
    prices = compute_prices(n, b)

    @test money ≈ 0
    @test prices ≈ [0.50, 0.50]
end

@testitem "cost share conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    b = 300
    price = 0.25
    cost = -100

    shares = cost_to_shares(cost, price, b)
    cost1 = shares_to_cost(price, shares, b)

    @test cost ≈ cost1
end

@testitem "share cost conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    b = 300
    price = 0.25
    shares = 20

    cost = shares_to_cost(price, shares, b)
    shares1 = cost_to_shares(cost, price, b)

    @test shares ≈ shares1
end

@testitem "cost to price conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_price
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    b = 300
    price = 0.30
    cost = 20

    shares = cost_to_shares(cost, price, b)
    new_price = shares_to_price(price, shares, b)
    cost1 = price_to_cost(new_price, price, b)

    @test cost ≈ cost1
end

@testitem "price to cost conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_price
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    b = 300
    price = 0.30
    cost = 20
    shares = 25

    new_price = shares_to_price(price, shares, b)
    cost = price_to_cost(new_price, price, b)
    shares1 = cost_to_shares(cost, price, b)

    @test shares ≈ shares1
end

@testitem "price to shares conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: price_to_shares
    using ABMPredictionMarkets: shares_to_price
    using Test

    b = 300
    price = 0.30
    new_price = 0.35

    shares = price_to_shares(new_price, price, b)
    new_price1 = shares_to_price(price, shares, b)

    @test new_price ≈ new_price1
end

@testitem "shares to price conversions" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: price_to_shares
    using ABMPredictionMarkets: shares_to_price
    using Test

    b = 300
    price = 0.30
    shares = 16

    new_price = shares_to_price(price, shares, b)
    shares1 = price_to_shares(new_price, price, b)

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
    n_options = 2
    upper_price = 0.98
    n_shares = fill(0.0, 2)

    b = set_elasticity(money, n_options, upper_price)
    n_shares[1] = cost_to_shares(-money, 0.50, b)
    prices = compute_prices(n_shares, b)

    @test prices[1] ≈ upper_price
end
