module PlotsExt

using Agents
using LaTeXStrings
using Plots
using PredictionMarketABM
using StatsBase

import PredictionMarketABM: plot_dashboard
import PredictionMarketABM: plot_depth_chart

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

    asks_shares1 = filter(x -> x.yes && (x.type == :ask), order_book)
    asks_shares2 = filter(x -> !x.yes && (x.type == :bid), order_book)
    asks = map(a -> a.price / 100, asks_shares1)
    push!(asks, map(a -> (100 - a.price) / 100, asks_shares2)...)

    ask_ecdf = ecdf(asks)
    bid_ecdf = ecdf(bids)
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

"""
    plot_dashboard(
        model;
        title = [j(B ∧ A)...],
        size = (1200, 800),
        layout = [
            Plots.GridLayout(2, 2),
            (label = :a, width = :auto, height = 0.20)
        ],
        kwargs...
    )

Plots an animated dashboard containing the following:

1. A depth chart for each market. 
2. Historical price for each market.
3. The unpacking factor based on two market sets. 

# Arguments

- `model`: an abm object for the prediction market simulation 

# Keywords

- `title = [(B ∧ A)...]`: a 1×n vector of labels for each market. 
- `size = (1200, 1000)`: size of dashboard animation 
- `layout`: the layout for the dashboard
- `kwargs...`: optional keyword arguments for the plots
"""
function plot_dashboard(
    model;
    title = [L"j(B \wedge A)" L"j(\bar{B} \wedge A)" L"j(B \wedge \bar{A})" L"j(\bar{B} \wedge \bar{A})" L"j(A)"],
    size = (1200, 1000),
    layout = [
        Plots.GridLayout(2, 2),
        (label = :a, width = :auto, height = 0.20)
    ],
    kwargs...
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
    animation = @animate for id ∈ Agents.schedule(model)
        agent_step!(model[id], model)
        p1 =
            plot_depth_chart.(
                model.order_books;
                xlims = (0, 1),
                ylims = (0, 60),
                default_config...,
                kwargs...
            )
        p2 = plot(
            model.market_prices;
            xlabel = "Time",
            ylabel = "Price",
            xlims = (1, n_agents),
            ylims = (0, 1),
            label = title,
            legend = :outerright,
            linewidth = 1.5,
            palette = :Dark2_5,
            default_config...
        )
        p3 = plot(
            compute_unpacking_factor(model);
            ylabel = "Unpacking Factor",
            xlims = (1, n_agents),
            leg = false,
            linewidth = 1.5,
            color = RGB(158 / 255, 120 / 255, 158 / 255),
            default_config...
        )
        hline!(p3, [1], color = :black, leg = false)
        plot(
            plot(p1...; title, layout = deepcopy(layout)),
            p2,
            p3;
            layout = [
                (label = :a, width = :auto, height = 0.70),
                (label = :b, width = :auto, height = 0.15),
                (label = :c, width = :auto, height = 0.15)
            ],
            size,
            kwargs...
        )
    end
    return animation
end

end
