# Example 

```@setup example
using Agents
using Distributions
using LaTeXStrings
using Plots
using PredictionMarketABM
using Random
using StatsBase
Random.seed!(93)
```


## Load Dependencies

```@example example
using Agents
using Distributions
using LaTeXStrings
using Plots
using PredictionMarketABM
using Random
Random.seed!(93)
```

## Run Model 
```@example example
n_agents = 1000
model = initialize(
    CompatibleAgent;
    n_agents,
    μ = [0.20, 0.25, 0.10, 0.45],
    η = 20.0,
    money = 50000,
    δ = 3,
    n_markets = 5
)
run!(model, 50)
```

## Plot Prices 

```@example example
market_titles =
    [L"j(B \wedge A)" L"j(\bar{B} \wedge A)" L"j(B \wedge \bar{A})" L"j(\bar{B} \wedge \bar{A})" L"j(A)"]
market_prices = map(i -> model.market_prices[i][1:n_agents:end], 1:5)
plot(
    market_prices,
    ylims = (0, 1),
    ylabel = "Price",
    grid = false,
    legendtitle = "Markets",
    label = market_titles
)
```
## Plot Trade Volume 

```@example example
trade_volume = compute_trade_volume.(model.trade_made, n_agents)
layout = @layout [grid(2, 2); b{0.2h}]
plot(
    trade_volume;
    layout,
    grid = false,
    label = false,
    title = market_titles,
    ylims = (0, 400),
    plot_title = "Trade Volume"
)
```

## Plot Depth Chart

```@example example
layout = @layout [grid(2, 2); b{0.2h}]

depth_charts = plot_depth_chart.(model.order_books)
plot(depth_charts...; layout, title = market_titles)
```

## Plot Autocorrelation

```@example example 
layout = @layout [grid(2, 2); b{0.2h}]
autocors = @. (autocor(filter(x -> !isnan(x), model.market_prices)))
plot(
    autocors;
    xlabel = "lag",
    leg = false, 
    grid = false, 
    layout,
    title = market_titles,
    plot_title = "Autocorrelation"
)
```

# Plot Dashboard

```julia
animation = plot_dashboard(model)
gif(animation, "temp.gif", fps = 8)
```

```@raw html
<img src="../assets/temp.gif" width=1200 height=800>
```