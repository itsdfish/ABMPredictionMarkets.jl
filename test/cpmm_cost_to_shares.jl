@testitem "cost to shares 1" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: cost_to_shares
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    cost = 1.241882774600781
    yes = true
    midx = 1

    n_shares = cost_to_shares(market, cost, midx, yes)

    @test n_shares ≈ 2.5322594160358616
end

@testitem "cost to shares 2" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: cost_to_shares
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )

    cost = 3.848661088472352
    yes = false
    midx = 1

    n_shares = cost_to_shares(market, cost, midx, yes)

    @test n_shares ≈ 7.369388265622825
end
