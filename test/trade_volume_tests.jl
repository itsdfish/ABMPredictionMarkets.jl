@testitem "trade volume tests" begin
    using ABMPredictionMarkets
    using Agents
    using Statistics
    using Test

    include("test_agent.jl")

    n_days = 100
    n_agents = 100
    μ = [0.05, 0.25, 0.10, 0.60]
    n_markets = length(μ)
    model = initialize(
        TestAgent;
        n_agents,
        μ,
        η = 20.0,
        money = 10_000,
        δ = 3
    )

    run!(model, n_days)
    # agents make the same number of trades, so both methods are the same 
    for i ∈ 1:n_markets
        volume1 = compute_trade_volume(model.trade_made[i], n_agents)
        volume2 =
            summarize_by_iteration(model.trade_made[i], model.iteration_ids[i]; fun = sum)
        @test volume1 == volume2
    end
end
