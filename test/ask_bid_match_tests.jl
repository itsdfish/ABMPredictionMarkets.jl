@testitem "no match 1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    bid = Order(; id = 1, yes = true, type = :bid, price = 20)
    bidx = 1
    success = transact!(bid, model, bidx)

    @test model[1].money ≈ 100
    for i ∈ 1:n_markets
        @test isempty(model[1].shares[i])
        if i == bidx
            @test model.order_books[i] == [bid]
        else
            @test isempty(model.order_books[i])
        end
    end
    @test !success
end

@testitem "no match 2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1

    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    push!(model[2].shares[bidx], Order(; id = 2, yes = true, type = :share, price = 20))

    push!(model.order_books[bidx], Order(; id = 2, yes = true, type = :ask, price = 39))

    bid = Order(; id = 1, yes = true, type = :bid, price = 40)

    success = transact!(bid, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        @test isempty(model[1].shares[i])
        if i == bidx
            @test bid ∈ model.order_books[i]
            @test length(model.order_books[i]) == 2
            @test length(model[2].shares[i]) == 1
        else
            @test isempty(model.order_books[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "no match 3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1

    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    push!(model[2].shares[bidx], Order(; id = 2, yes = true, type = :share, price = 20))

    push!(model.order_books[bidx], Order(; id = 2, yes = true, type = :ask, price = 40))

    bid = Order(; id = 1, yes = false, type = :bid, price = 40)

    success = transact!(bid, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        @test isempty(model[1].shares[i])
        if i == bidx
            @test bid ∈ model.order_books[i]
            @test length(model.order_books[i]) == 2
            @test length(model[2].shares[i]) == 1
        else
            @test isempty(model.order_books[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "no match 4" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1

    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    push!(model[2].shares[bidx], Order(; id = 2, yes = true, type = :share, price = 20))

    push!(model.order_books[bidx], Order(; id = 2, yes = true, type = :ask, price = 40))

    bid = Order(; id = 1, yes = true, type = :ask, price = 40)

    success = transact!(bid, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        @test isempty(model[1].shares[i])
        if i == bidx
            @test bid ∈ model.order_books[i]
            @test length(model.order_books[i]) == 2
            @test length(model[2].shares[i]) == 1
        else
            @test isempty(model.order_books[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "does not match 5" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1

    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    push!(model[2].shares[bidx], Order(; id = 2, yes = true, type = :share, price = 20))

    push!(model.order_books[bidx + 1], Order(; id = 2, yes = true, type = :ask, price = 40))

    bid = Order(; id = 1, yes = true, type = :bid, price = 40)

    success = transact!(bid, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        @test isempty(model[1].shares[i])
        if i == bidx
            @test bid ∈ model.order_books[i]
            @test length(model.order_books[i]) == 1
            @test length(model[2].shares[i]) == 1
        elseif i == (bidx + 1)
            @test length(model.order_books[i]) == 1
        else
            @test isempty(model.order_books[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "match bid" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1

    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    push!(model[2].shares[bidx], Order(; id = 2, yes = true, type = :share, price = 20))

    push!(model.order_books[bidx], Order(; id = 2, yes = true, type = :ask, price = 40))

    bid = Order(; id = 1, yes = true, type = :bid, price = 40)
    model[1].money -= bid.price
    model[1].bid_reserve += bid.price

    success = transact!(bid, model, bidx)

    @test model[1].money ≈ 60
    @test model[1].bid_reserve ≈ 0
    @test model[2].money ≈ 140
    for i ∈ 1:n_markets
        @test isempty(model.order_books[i])
        if i == bidx
            @test model[1].shares[i] ==
                  [Order(; id = 1, yes = true, type = :share, price = 40)]
        else
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test success
end

@testitem "match ask" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 4
    bidx = 1

    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        bid_reserve = 0,
        shares = init(Order, n_markets)
    )

    push!(model[1].shares[bidx], Order(; id = 1, yes = true, type = :share, price = 20))

    push!(model.order_books[bidx], Order(; id = 2, yes = true, type = :bid, price = 40))
    model[2].money -= 40
    model[2].bid_reserve += 40

    ask = Order(; id = 1, yes = true, type = :ask, price = 40)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 140
    @test model[2].money ≈ 60
    @test model[2].bid_reserve == 0
    for i ∈ 1:n_markets
        @test isempty(model.order_books[i])
        if i == bidx
            @test model[2].shares[i] ==
                  [Order(; id = 2, yes = true, type = :share, price = 40)]
        else
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test success
end
