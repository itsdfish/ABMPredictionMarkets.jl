@testitem "price_to_cost 1" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: compute_price
    using ABMPredictionMarkets: get_reserves
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: update_reserves!
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    yes = true
    midx = 1
    price = compute_price(market, midx, yes)
    tarcompute_price = price + 0.05

    cost = price_to_cost(market, tarcompute_price, midx, yes)
    n_shares = cost_to_shares(market, cost, midx, yes)
    yes_reserves1, no_reserves1 = update_reserves!(market, n_shares, cost, midx, yes)
    tarcompute_price = compute_price(market, midx, yes)

    @test cost ≈ 10.006265477226084
    @test yes_reserves1 ≈ 90.470791974412
    @test no_reserves1 ≈ 105.00626547722608
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1
    @test tarcompute_price ≈ tarcompute_price
end

@testitem "price_to_cost 2" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: compute_price
    using ABMPredictionMarkets: get_reserves
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: update_reserves!
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    yes = true
    midx = 1
    price = compute_price(market, midx, yes)
    tarcompute_price = price - 0.05

    cost = price_to_cost(market, tarcompute_price, midx, yes)
    n_shares = cost_to_shares(market, cost, midx, yes)
    yes_reserves1, no_reserves1 = update_reserves!(market, n_shares, cost, midx, yes)
    tarcompute_price = compute_price(market, midx, yes)

    @test cost ≈ -9.09731627815675
    @test yes_reserves1 ≈ 110.59025851580408
    @test no_reserves1 ≈ 85.90268372184325
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1
    @test tarcompute_price ≈ tarcompute_price
end

@testitem "price_to_cost 3" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: compute_price
    using ABMPredictionMarkets: get_reserves
    using ABMPredictionMarkets: price_to_cost
    using ABMPredictionMarkets: update_reserves!
    using Test

    midx = 1

    for i ∈ 1:100
        yes_reserves = 100
        no_reserves = 95
        market = CPMM(
            yes_reserves = [yes_reserves],
            no_reserves = [no_reserves]
        )
        yes = rand(Bool)
        tarcompute_price = rand()
        cost = price_to_cost(market, tarcompute_price, midx, yes)
        n_shares = cost_to_shares(market, cost, midx, yes)
        update_reserves!(market, n_shares, cost, midx, yes)

        price = compute_price(market, midx, yes)
        @test price ≈ tarcompute_price
    end
end
