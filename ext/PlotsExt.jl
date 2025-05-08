module PlotsExt

using Agents
using LaTeXStrings
using Plots
using ABMPredictionMarkets
using StatsBase

import ABMPredictionMarkets: plot_dashboard
import ABMPredictionMarkets: plot_depth_chart

"""
    plot_depth_chart(order_book::Vector{Order}; kwargs...)

Creates a market depth chart to analyze supply and demand dynamics. The red area on the left represents the reversed cumulative distribution for bids.
The blue area on the right represents the cumulative distribution for asks. 
The mid market price is represented by vertical black line.

# Arguments

- `order_book::Vector{Order}`: a vector of orders (bids and asks) representing the order book (i.e. outstanding orders)

# Keywords

- `config...`: optional keyword arguments to the function `plot`
"""
function plot_depth_chart(order_book::Vector{Order}; config...)
    bid_shares1 = filter(x -> x.yes && (x.type == :bid), order_book)
    bid_shares2 = filter(x -> !x.yes && (x.type == :ask), order_book)

    bids = map(b -> b.price / 100, bid_shares1)
    push!(bids, map(b -> (100 - b.price) / 100, bid_shares2)...)
    bid_weights = map(b -> b.quantity, bid_shares1)
    push!(bid_weights, map(b -> b.quantity, bid_shares2)...)

    asks_shares1 = filter(x -> x.yes && (x.type == :ask), order_book)
    asks_shares2 = filter(x -> !x.yes && (x.type == :bid), order_book)

    asks = map(a -> a.price / 100, asks_shares1)
    push!(asks, map(a -> (100 - a.price) / 100, asks_shares2)...)
    ask_weights = map(b -> b.quantity, asks_shares1)
    push!(ask_weights, map(b -> b.quantity, asks_shares2)...)

    ask_ecdf = ecdf(asks; weights = Weights(ask_weights))
    bid_ecdf = ecdf(bids; weights = Weights(bid_weights))
    p_ask = isempty(asks) ? range(0, 0, 0) : range(extrema(asks)..., length = 100)
    p_bid = isempty(bids) ? range(0, 0, 0) : range(extrema(bids)..., length = 100)

    depth_plot = plot(
        p_ask,
        ask_ecdf(p_ask) .* length(asks);
        grid = false,
        leg = false,
        xlabel = "Price",
        ylabel = "Quantity",
        fillrange = [0],
        linewidth = 2,
        fillalpha = 0.70,
        color = RGB(74 / 255, 84 / 255, 138 / 255),
        config...
    )
    plot!(
        p_bid,
        (1 .- bid_ecdf(p_bid)) * length(bids),
        alpha = 0.70,
        fillrange = [0],
        linewidth = 2,
        fillalpha = 0.70,
        color = RGB(138 / 255, 74 / 255, 74 / 255);
        config...
    )
    if !isempty(asks) && !isempty(bids)
        mid_point = (minimum(asks) + maximum(bids)) / 2
        vline!([mid_point], color = :black)
    end
    return depth_plot
end

make_layout(x) = (Int(ceil(sqrt(length(x)))), Int(ceil(sqrt(length(x)))))
make_title(x) = reshape([L"e_{%$i}" for i ∈ 1:length(x)], 1, length(x))
"""
    plot_dashboard(
        model;
        title = make_title(model.market_prices),
        size = (1200, 1000),
        depth_chart_layout = make_layout(model.market_prices),
        outer_layout = [(label = :a, width = :auto, height = 0.70), (label = :b, width = :auto, height = 0.30)],
        add_unpacking_factor = false,
        n_days = 1,
        kwargs...
    )

Plots an animated dashboard containing the following:

1. A depth chart for each market. 
2. Historical price for each market.
3. Optional unpacking factor based on two market sets. 

# Arguments

- `model`: an abm object for the prediction market simulation 

# Keywords

- `title`: a 1×n vector of labels for each market. By default, each element is eᵢ
- `depth_chart_layout`: the layout of the depth charts. By default, the smallest possible 2D grid is used.
- `size = (1200, 1000)`: size of dashboard animation 
- `outer_layout`: the layout for the dashboard
- `add_unpacking_factor = false`: includes unpacking factor plot if true. If set to true, default layouts will need to be overwritten.
- `n_days = 1`: the number of days to simulate the prediction market
- `depth_chart_config = ()`: optional keyword arguments for the depth charts
- `price_chart_config = ()`: optional keyword arguments for price charts
"""
function plot_dashboard(
    model;
    title = make_title(model.market_prices),
    size = (1200, 1000),
    depth_chart_layout = make_layout(model.market_prices),
    outer_layout = [
        (label = :a, width = :auto, height = 0.70),
        (label = :b, width = :auto, height = 0.30)
    ],
    add_unpacking_factor = false,
    n_days = 1,
    depth_chart_config = (),
    price_chart_config = ()
)
    default_config = (
        legendfontsize = 10,
        axis = font(12),
        grid = false,
        left_margin = 6Plots.mm,
        right_margin = 6Plots.mm,
        titlefontsize = 14
    )

    n_agents = nagents(model)
    animation = @animate for day ∈ 1:n_days, id ∈ Agents.schedule(model)
        agent_step!(model[id], model)
        p1 =
            plot_depth_chart.(
                model.order_books;
                xlims = (0, 1),
                ylims = (0, n_agents / 2),
                default_config...,
                depth_chart_config...
            )
        p2 = Plots.Plot[]
        push!(
            p2,
            plot(
                model.market_prices;
                xlabel = "Steps",
                ylabel = "Price",
                xlims = (1, n_agents * n_days),
                ylims = (0, 1),
                label = title,
                legend = :outerright,
                linewidth = 1.5,
                palette = :Dark2_5,
                default_config...,
                price_chart_config...
            )
        )
        if add_unpacking_factor
            push!(
                p2,
                plot(
                    compute_unpacking_factor(model);
                    ylabel = "Unpacking Factor",
                    xlims = (1, n_agents),
                    leg = false,
                    linewidth = 1.5,
                    color = RGB(158 / 255, 120 / 255, 158 / 255),
                    default_config...
                )
            )
            hline!(p2[end], [1], color = :black, leg = false)
        end
        plot(
            plot(p1...; title, layout = deepcopy(depth_chart_layout)),
            p2...;
            layout = outer_layout,
            size
        )
    end
    return animation
end

end
