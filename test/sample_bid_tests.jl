@testitem "bounds 1" begin
    using Agents
    using ABMPredictionMarkets: sample_bid
    using Test

    judgment = 10
    δ = 5
    bids = map(_ -> sample_bid(judgment, δ), 1:10_000)
    @test minimum(bids) ≈ judgment - δ
    @test maximum(bids) ≈ judgment - 1
end

@testitem "bounds 2" begin
    using Agents
    using ABMPredictionMarkets: sample_bid
    using Test

    judgment = 10
    δ = 20
    bids = map(_ -> sample_bid(judgment, δ), 1:10_000)
    @test minimum(bids) ≈ 0
    @test maximum(bids) ≈ judgment - 1
end
