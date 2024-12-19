@testitem "1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: get_market_info
    using Test

    order_books = [
        Order(; id = 1, yes = true, type = :bid, price = 30),
        Order(; id = 1, yes = true, type = :bid, price = 31),
        Order(; id = 1, yes = false, type = :bid, price = 71),
        Order(; id = 1, yes = false, type = :bid, price = 68),
        Order(; id = 1, yes = true, type = :ask, price = 32),
        Order(; id = 1, yes = true, type = :ask, price = 33),
        Order(; id = 1, yes = false, type = :ask, price = 68),
        Order(; id = 1, yes = false, type = :ask, price = 73)
    ]

    max_yes_bid, min_yes_ask = get_market_info(order_books; yes = true)
    @test max_yes_bid ≈ 32
    @test min_yes_ask ≈ 29
end

@testitem "2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: get_market_info
    using Test

    order_books = [
        Order(; id = 1, yes = true, type = :bid, price = 30),
        Order(; id = 1, yes = true, type = :bid, price = 31),
        Order(; id = 1, yes = false, type = :bid, price = 71),
        Order(; id = 1, yes = false, type = :bid, price = 68),
        Order(; id = 1, yes = true, type = :ask, price = 32),
        Order(; id = 1, yes = true, type = :ask, price = 33),
        Order(; id = 1, yes = false, type = :ask, price = 68),
        Order(; id = 1, yes = false, type = :ask, price = 73)
    ]

    max_yes_bid, min_yes_ask = get_market_info(order_books; yes = true)
    max_no_bid, min_no_ask = get_market_info(order_books; yes = false)

    @test max_yes_bid ≈ (100 - min_no_ask)
    @test min_yes_ask ≈ (100 - max_no_bid)
end

@testitem "3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: get_market_info
    using Test

    order_books = [
        Order(; id = 1, yes = true, type = :bid, price = 30),
        Order(; id = 1, yes = true, type = :bid, price = 33),
        Order(; id = 1, yes = false, type = :bid, price = 71),
        Order(; id = 1, yes = false, type = :bid, price = 68),
        Order(; id = 1, yes = true, type = :ask, price = 28),
        Order(; id = 1, yes = true, type = :ask, price = 33),
        Order(; id = 1, yes = false, type = :ask, price = 68),
        Order(; id = 1, yes = false, type = :ask, price = 73)
    ]

    max_yes_bid, min_yes_ask = get_market_info(order_books; yes = true)
    @test max_yes_bid ≈ 33
    @test min_yes_ask ≈ 28
end

@testitem "4" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: get_market_info
    using Test

    order_books = [
        Order(; id = 1, yes = true, type = :bid, price = 30),
        Order(; id = 1, yes = true, type = :bid, price = 33),
        Order(; id = 1, yes = false, type = :bid, price = 71),
        Order(; id = 1, yes = false, type = :bid, price = 68),
        Order(; id = 1, yes = true, type = :ask, price = 28),
        Order(; id = 1, yes = true, type = :ask, price = 33),
        Order(; id = 1, yes = false, type = :ask, price = 68),
        Order(; id = 1, yes = false, type = :ask, price = 73)
    ]

    max_yes_bid, min_yes_ask = get_market_info(order_books; yes = true)
    max_no_bid, min_no_ask = get_market_info(order_books; yes = false)

    @test max_yes_bid ≈ (100 - min_no_ask)
    @test min_yes_ask ≈ (100 - max_no_bid)
end
