@testitem "test 3" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: ask_bid_match!
    using Agents
    # using Plots
    using Random
    using Statistics
    using Test
    include("test_agent.jl")

    #Random.seed!(988)

    n_days = 5
    n_agents = 1000
    μ = [0.40, .10]
    n_markets = length(μ)
    model = initialize(
        TestAgent;
        n_agents,
        μ,
        η = 20.0,
        money = 20_000,
        δ = 3,
        max_quantity = 3
    )

    run!(model, n_days)

    order_book = model.order_books[1]

    agent = add_agent!(
        model;
        judgments = [100,100],
        money = 100_000,
        bid_reserve = 0,
        δ = 3,
        max_quantity = 100_000,
        shares = init(Order, n_markets)
    )

    temp_flag = true 
    while true 
        sort!(order_book; rev = false, by = x -> x.yes ? x.price : 100 - x.price)
        idx = findfirst(x -> x.type == :ask, order_book)
        isnothing(idx) ? break : nothing 

        ask = order_book[idx]
        total_cost = ask.price * ask.quantity
        agent.money -= total_cost
        agent.bid_reserve += total_cost

        proposal = Order(;
            id = agent.id,
            price = ask.price,
            yes = ask.yes,
            type = :bid,
            quantity = ask.quantity,
        )
        
        ask_bid_match!(proposal, model, 1, idx)
        deleteat!(order_book, idx)
        @test agent.bid_reserve == 0
        
       if agent.bid_reserve ≠ 0 && temp_flag 
            println("proposal $proposal")
            println("bid_reserve $(agent.bid_reserve)")
            println("ask $ask")
            global temp_flag = false
       end
    end
end
