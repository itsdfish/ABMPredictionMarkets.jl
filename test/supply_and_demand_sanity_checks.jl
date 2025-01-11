@testitem "bounds" begin
    using Agents
    using ABMPredictionMarkets: get_market_info
    using ABMPredictionMarkets: agent_step!
    using ABMPredictionMarkets: sample_ask
    using Test

    include("test_agent.jl")

    n_agents = 1000
    n_reps = 10
    model = initialize(
        TestAgent;
        n_agents = 100,
        μ = [0.20, 0.25, 0.10, 0.45],
        η = 20.0,
        money = 10_000,
        δ = 3,
    )

    for _ ∈ 1:n_reps
        for id ∈ Agents.schedule(model)
            agent_step!(model[id], model)
            max_bid, min_ask = get_market_info(model.order_books[1]; yes = true)
            @test max_bid ≤ min_ask
        end
    end
end
