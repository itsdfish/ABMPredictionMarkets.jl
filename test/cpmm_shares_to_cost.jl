@testitem "shares to cost 1" begin 
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    n_shares = -10
    yes = true
    midx = 1

    # sell n_shares 
    cost = shares_to_cost(market, n_shares, midx, yes)

    @test cost ≈ -4.743926019914241
end

@testitem "shares to cost 2" begin 
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    n_shares = 10
    yes = true
    midx = 1

    # buy n_shares 
    cost = shares_to_cost(market, n_shares, midx, yes)

    @test cost ≈ 5
end

@testitem "shares to cost 3" begin 
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    n_shares = -10
    yes = false
    midx = 1

    # sell n_shares 
    cost = shares_to_cost(market, n_shares, midx, yes)

    @test cost ≈ -5
end

@testitem "shares to cost 4" begin 
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    n_shares = 10
    yes = false
    midx = 1

    # buy n_shares 
    cost = shares_to_cost(market, n_shares, midx, yes)

    @test cost ≈ 5.256073980085759
end