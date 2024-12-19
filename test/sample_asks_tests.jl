@testitem "bounds 1" begin
    using Agents
    using ABMPredictionMarkets: sample_ask
    using Test

    judgment = 10
    δ = 5
    bids = map(_ -> sample_ask(judgment, δ), 1:10_000)

    @test minimum(bids) ≈ judgment + 1
    @test maximum(bids) ≈ judgment + δ
end

@testitem "bounds 2" begin
    using Agents
    using ABMPredictionMarkets: sample_ask
    using Test

    judgment = 90
    δ = 20
    bids = map(_ -> sample_ask(judgment, δ), 1:10_000)

    @test minimum(bids) ≈ judgment + 1
    @test maximum(bids) ≈ 100
end
