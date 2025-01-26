@testitem "smoke test" begin
    using ABMPredictionMarkets
    using Agents
    using Plots
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

    market_prices = map(i -> model.market_prices[i][1:n_agents:end], 1:n_markets)
    plot(
        market_prices,
        ylims = (0, 1),
        ylabel = "Price",
        grid = false,
        legendtitle = "Markets"
    )
    hline!(μ, color = :black, linestyle = :dash)

    # depth_charts = plot_depth_chart.(model.order_books; ylims = (0, 50))
    # plot(depth_charts...)

    # trade_volume = compute_trade_volume.(model.trade_made, n_agents)
    # layout = @layout [grid(2, 2)]
    # plot(
    #     trade_volume;
    #     layout,
    #     grid = false,
    #     label = false,
    #     ylims = (0, 100),
    #     plot_title = "Trade Volume"
    # )

    # market_prices = map(x -> filter(x -> !isnan(x), x), model.market_prices)
    # [mean.(market_prices) μ]
end
