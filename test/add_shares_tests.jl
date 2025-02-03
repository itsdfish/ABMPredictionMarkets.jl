@testitem "add_shares! 1" begin
    using ABMPredictionMarkets: add_shares!

    shares = [
        Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35),
        Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 34)
    ]

    share = Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35)
    add_shares!(shares, share)

    @test length(shares) == 2
    @test (shares[1].price == 35) && (shares[1].quantity == 4)
    @test (shares[2].price == 34) && (shares[2].quantity == 2)
end

@testitem "add_shares! 2" begin
    using ABMPredictionMarkets: add_shares!

    shares = [
        Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35),
        Order(; id = 1, yes = false, type = :bid, quantity = 2, price = 35)
    ]

    share = Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35)
    add_shares!(shares, share)

    @test length(shares) == 2
    @test (shares[1].price == 35) && shares[1].yes && (shares[1].quantity == 4)
    @test (shares[2].price == 35) && !shares[2].yes && (shares[2].quantity == 2)
end

@testitem "add_shares! 2" begin
    using ABMPredictionMarkets: add_shares!

    shares = [
        Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35),
        Order(; id = 1, yes = false, type = :bid, quantity = 2, price = 35)
    ]

    share = Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35)
    add_shares!(shares, share)

    @test length(shares) == 2
    @test (shares[1].price == 35) && shares[1].yes && (shares[1].quantity == 4)
    @test (shares[2].price == 35) && !shares[2].yes && (shares[2].quantity == 2)
end

@testitem "add_shares! 3" begin
    using ABMPredictionMarkets: add_shares!

    shares = [
        Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 34),
        Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 33)
    ]

    share = Order(; id = 1, yes = true, type = :bid, quantity = 2, price = 35)
    add_shares!(shares, share)

    @test length(shares) == 3
    @test (shares[1].price == 34) && shares[1].yes && (shares[1].quantity == 2)
    @test (shares[2].price == 33) && shares[2].yes && (shares[2].quantity == 2)
    @test (shares[3].price == 35) && shares[2].yes && (shares[3].quantity == 2)
end
