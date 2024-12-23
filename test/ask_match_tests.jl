@testitem "no match 1" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
    )

    remove_all!(model)

    agent = add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    share = Order(; id = 1, yes = false, type = :share, price = 20)
    push!(agent.shares[bidx], share)
    ask = Order(; id = 1, yes = true, type = :ask, price = 20)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 100
    for i ∈ 1:n_markets
        if i == bidx
            @test model.order_books[i] == [ask]
            @test model[1].shares[i] == [share]
        else
            @test isempty(model.order_books[i])
            @test isempty(model[1].shares[i])
        end
    end
    @test !success
end

@testitem "no match 2" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    share1 = Order(; id = 1, yes = false, type = :share, price = 20)
    push!(model[1].shares[bidx], share1)

    share2 = Order(; id = 2, yes = true, type = :share, price = 20)
    push!(model[2].shares[bidx], share2)

    ask = Order(; id = 1, yes = false, type = :ask, price = 39)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        if i == bidx
            @test model.order_books[i] == [ask]
            @test model[1].shares[i] == [share1]
            @test model[2].shares[i] == [share2]
        else
            @test isempty(model.order_books[i])
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "no match 3" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    share1 = Order(; id = 1, yes = false, type = :share, price = 20)
    push!(model[1].shares[bidx], share1)

    share2 = Order(; id = 2, yes = true, type = :share, price = 20)
    push!(model[2].shares[bidx], share2)

    share = Order(; id = 2, yes = true, type = :ask, price = 60)
    push!(model.order_books[bidx], share)

    ask = Order(; id = 1, yes = true, type = :ask, price = 40)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        if i == bidx
            @test model.order_books[i] == [share, ask]
            @test model[1].shares[i] == [share1]
            @test model[2].shares[i] == [share2]
        else
            @test isempty(model.order_books[i])
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "no match 4" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    share1 = Order(; id = 1, yes = false, type = :share, price = 20)
    push!(model[1].shares[bidx], share1)

    share2 = Order(; id = 2, yes = true, type = :share, price = 20)
    push!(model[2].shares[bidx], share2)

    share = Order(; id = 2, yes = false, type = :bid, price = 60)
    push!(model.order_books[bidx], share)

    ask = Order(; id = 1, yes = true, type = :ask, price = 40)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        if i == bidx
            @test model.order_books[i] == [share, ask]
            @test model[1].shares[i] == [share1]
            @test model[2].shares[i] == [share2]
        else
            @test isempty(model.order_books[i])
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "no match 5" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    share1 = Order(; id = 1, yes = false, type = :share, price = 20)
    push!(model[1].shares[bidx], share1)

    share2 = Order(; id = 2, yes = true, type = :share, price = 20)
    push!(model[2].shares[bidx], share2)

    share = Order(; id = 2, yes = false, type = :bid, price = 60)
    push!(model.order_books[bidx + 1], share)

    ask = Order(; id = 1, yes = true, type = :ask, price = 40)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 100
    @test model[2].money ≈ 100
    for i ∈ 1:n_markets
        if i == bidx
            @test model.order_books[i] == [ask]
            @test model[1].shares[i] == [share1]
            @test model[2].shares[i] == [share2]
        elseif i == (bidx + 1)
            @test model.order_books[i] == [share]
        else
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test !success
end

@testitem "match" begin
    using Agents
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_match!
    using ABMPredictionMarkets: transact!
    using ABMPredictionMarkets: init
    using Test

    include("test_agent.jl")

    n_markets = 5
    bidx = 1
    model = initialize(
        TestAgent;
        n_agents = 4,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 1,
        n_markets
    )

    remove_all!(model)

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    add_agent!(
        model;
        δ = 3,
        judgments = [50, 20, 30, 20, 30],
        money = 100,
        shares = init(Order, n_markets)
    )

    share1a = Order(; id = 1, yes = true, type = :share, price = 20)
    share1b = Order(; id = 1, yes = false, type = :share, price = 20)
    push!(model[1].shares[bidx], share1a)
    push!(model[1].shares[bidx], share1b)

    share2a = Order(; id = 2, yes = true, type = :share, price = 20)
    share2b = Order(; id = 2, yes = false, type = :share, price = 20)
    push!(model[2].shares[bidx], share2a)
    push!(model[2].shares[bidx], share2b)

    share = Order(; id = 2, yes = false, type = :ask, price = 60)
    push!(model.order_books[bidx], share)

    ask = Order(; id = 1, yes = true, type = :ask, price = 40)

    success = transact!(ask, model, bidx)

    @test model[1].money ≈ 140
    @test model[2].money ≈ 160
    for i ∈ 1:n_markets
        @test isempty(model.order_books[i])
        if i == bidx
            @test model[1].shares[i] == [share1b]
            @test model[2].shares[i] == [share2a]
        else
            @test isempty(model[1].shares[i])
            @test isempty(model[2].shares[i])
        end
    end
    @test success
end
