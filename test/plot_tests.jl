@testitem "plots" begin
    using ABMPredictionMarkets
    using ABMPredictionMarkets: init
    using Agents
    using Distributions
    using LaTeXStrings
    using Plots
    using Random
    using StatsBase
    Random.seed!(93)

    @agent struct TestAgent(NoSpaceAgent) <: MarketAgent
        judgments::Vector{Int}
        δ::Int
        money::Int
        bid_reserve::Int
        max_quantity::Int
        shares::Vector{Vector{Order}}
    end

    import ABMPredictionMarkets: initialize
    function initialize(
        ::Type{<:TestAgent};
        n_agents,
        μ,
        η,
        δ,
        money,
        max_quantity = 1
    )
        space = nothing
        n_markets = length(μ)
        model = StandardABM(
            TestAgent,
            space;
            properties = CDA(; n_markets),
            agent_step!,
            scheduler = Schedulers.Randomly()
        )
        for _ ∈ 1:n_agents
            add_agent!(
                model;
                judgments = rand(DiscreteDirichlet(μ, η)),
                money,
                bid_reserve = 0,
                δ,
                max_quantity,
                shares = init(Order, n_markets)
            )
        end
        return model
    end

    n_agents = 100
    μ = [0.20, 0.25, 0.10, 0.45]
    model = initialize(
        TestAgent;
        n_agents,
        μ,
        η = 20.0,
        money = 10_000,
        δ = 3
    )
    run!(model, 50)

    market_titles = [L"e_{1}" L"e_{2}" L"e_{3}" L"e_{4}"]
    market_prices = summarize_by_iteration.(model.market_prices, model.iteration_ids)
    plot(
        market_prices,
        ylims = (0, 1),
        ylabel = "Market Price",
        grid = false,
        legendtitle = "Markets",
        label = market_titles
    )
    hline!(μ, color = :black, linestyle = :dash, label = nothing)

    trade_volume =
        summarize_by_iteration.(model.trade_volume, model.iteration_ids; fun = sum)

    plot(
        trade_volume;
        layout = (2, 2),
        grid = false,
        label = false,
        title = market_titles,
        ylims = (0, 100),
        plot_title = "Trade Volume"
    )

    depth_charts = plot_depth_chart.(model.order_books)
    plot(depth_charts...; layout = (2, 2), title = market_titles)

    autocors = @. (autocor(filter(x -> !isnan(x), model.market_prices)))
    plot(
        autocors;
        xlabel = "lag",
        leg = false,
        grid = false,
        layout = (2, 2),
        title = market_titles,
        plot_title = "Autocorrelation"
    )

    model = initialize(
        TestAgent;
        n_agents,
        μ,
        η = 20.0,
        money = 10_000,
        δ = 3,
        max_quantity = 5
    )

    animation = plot_dashboard(model; n_days = 2)
    gif(animation, "temp.gif", fps = 8)
end
