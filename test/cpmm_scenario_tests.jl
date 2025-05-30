@testitem "scenario 1" begin 
    using ABMPredictionMarkets
    using ABMPredictionMarkets: get_price
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: update_reserves!
    using ABMPredictionMarkets: update_reserves
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: price_to_cost

    using Test
    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )
    initial_money = 100
    money = initial_money
    n_shares = 10
    yes = true
    midx = 1
    price1 = get_price(market, midx, yes)

    # buy n_shares 
    cost = shares_to_cost(market, n_shares, midx, yes)
    yes_reserves1, no_reserves1 = update_reserves!(market, midx, n_shares, cost, yes)
    money -= cost
    price2 = get_price(market, midx, yes)
    @test price2 > price1 
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1

    # sell n_shares 
    cost = shares_to_cost(market, -n_shares, midx, yes)
    yes_reserves2, no_reserves2 = update_reserves!(market, midx, -n_shares, cost, yes)
    money -= cost
    price3 = get_price(market, midx, yes)
    @test price1 ≈ price3 
    @test yes_reserves ≈ yes_reserves2
    @test no_reserves ≈ no_reserves2
    @test money ≈ initial_money
    @test yes_reserves * no_reserves ≈ yes_reserves2 * no_reserves2
end

@testitem "scenario 2" begin 
    using ABMPredictionMarkets
    using ABMPredictionMarkets: get_price
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: update_reserves!
    using ABMPredictionMarkets: update_reserves
    using ABMPredictionMarkets: cost_to_shares
    using ABMPredictionMarkets: price_to_cost
    using Test
    
    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )
    initial_money = 100
    money = initial_money
    n_shares = 10
    yes = false
    midx = 1
    price1 = get_price(market, midx, yes)

    # buy n_shares 
    cost = shares_to_cost(market, n_shares, midx, yes)
    yes_reserves1, no_reserves1 = update_reserves!(market, midx, n_shares, cost, yes)
    money -= cost
    price2 = get_price(market, midx, yes)
    @test price2 > price1 
    @test yes_reserves * no_reserves ≈ yes_reserves1 * no_reserves1

    # sell n_shares 
    cost = shares_to_cost(market, -n_shares, midx, yes)
    yes_reserves2, no_reserves2 = update_reserves!(market, midx, -n_shares, cost, yes)
    money -= cost
    price3 = get_price(market, midx, yes)
    @test price1 ≈ price3 
    @test yes_reserves ≈ yes_reserves2
    @test no_reserves ≈ no_reserves2
    @test money ≈ initial_money
    @test yes_reserves * no_reserves ≈ yes_reserves2 * no_reserves2
end