@testitem "summarize_by_iteration test 1" begin
    using ABMPredictionMarkets
    using Test

    market_prices = [1, 2, 3, 2, 3, 4, 3, 4, 5]
    iteration_ids = [1, 1, 1, 2, 2, 2, 3, 3, 3]

    x = summarize_by_iteration(market_prices, iteration_ids)
    @test x == [3, 4, 5]
end

@testitem "summarize_by_iteration test 2" begin
    using ABMPredictionMarkets
    using Test

    market_prices = [1, 2, 3, 2, 3, 4, 3, 4, 5]
    iteration_ids = [1, 1, 1, 2, 2, 2, 3, 3, 3]

    x = summarize_by_iteration(market_prices, iteration_ids; fun = sum)
    @test x == [6, 9, 12]
end
