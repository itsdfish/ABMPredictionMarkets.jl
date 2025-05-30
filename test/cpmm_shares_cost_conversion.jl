@testitem "cpmm shares and cost conversions" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: shares_to_cost
    using ABMPredictionMarkets: cost_to_shares
    using Test

    yes_reserves = 100
    no_reserves = 95
    market = CPMM(
        yes_reserves = [yes_reserves],
        no_reserves = [no_reserves]
    )
    midx = 1

    for _ ∈ 1:100
        yes = rand(Bool)
        n_shares = rand() * 10 - 20
        cost = shares_to_cost(market, n_shares, midx, yes)
        n_shares1 = cost_to_shares(market, cost, midx, yes)
        @test n_shares ≈ n_shares1
    end
end
