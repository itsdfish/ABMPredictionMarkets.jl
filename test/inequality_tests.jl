@testitem "not equal" begin
    using Agents
    using ABMPredictionMarkets
    using Test

    order1 = Order(; id = 1, yes = true, type = :bid, quantity = 1, price = 50)
    order2 = Order(; id = 1, yes = true, type = :bid, quantity = 1, price = 50)

    @test !(order1 ≠ order2)
end

@testitem "not equal 1" begin
    using Agents
    using ABMPredictionMarkets
    using Test

    order1 = Order(; id = 1, yes = true, type = :bid, quantity = 1, price = 50)
    order2 = Order(; id = 2, yes = true, type = :bid, quantity = 1, price = 50)

    @test order1 ≠ order2
end

@testitem "not equal 2" begin
    using Agents
    using ABMPredictionMarkets
    using Test

    order1 = Order(; id = 1, yes = true, type = :bid, quantity = 1, price = 50)
    order2 = Order(; id = 1, yes = false, type = :bid, quantity = 1, price = 50)

    @test order1 ≠ order2
end

@testitem "not equal 3" begin
    using Agents
    using ABMPredictionMarkets
    using Test

    order1 = Order(; id = 1, yes = true, type = :bid, quantity = 1, price = 50)
    order2 = Order(; id = 1, yes = true, type = :bid, quantity = 1, price = 51)

    @test order1 ≠ order2
end
