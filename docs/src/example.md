# Example 

```@setup example
using Agents
using Distributions
using LaTeXStrings
using Plots
using ABMPredictionMarkets
using Random
using StatsBase
Random.seed!(93)
```

The page provides a working example of simulating a prediction market with `ABMPredictionMarkets.jl`. In the example below, 100 agents trade shares in four prediction markets. The belief distributions across agents are distributed such that the sum of prices is approximately 1. 

## Load Dependencies

The next step is to load the required dependencies for simulation and plotting.

```@example example
using ABMPredictionMarkets
using ABMPredictionMarkets: init
using Agents
using Distributions
using LaTeXStrings
using Plots
using Random
using StatsBase
Random.seed!(93)
```

## Create Agent 

Below, we define an agent type which is a subtype of `MarketAgent`. The subjective judgments are stored in the field `judgements` for each market on a scale of 0 to 100 (e.g., cents). The money and bid reserve are also expressed in terms of cents. The maximum quantity is the maximum number of shares traded per day per agent. Finally, the field `shares` stores shares in separate sub-vectors for each market. 

```@example example 
@agent struct TestAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Int}
    δ::Int
    money::Int
    bid_reserve::Int
    max_quantity::Int
    shares::Vector{Vector{Order}}
end
```

## Initialize Model 

The function defined below initializes the agent-based model.

```@example example
import ABMPredictionMarkets: initialize
function initialize(
    ::Type{<:TestAgent};
    n_agents,
    μ,
    η,
    δ,
    money,
    max_quantity = 1,
    info_times = Int[]
)
    space = nothing
    n_markets = length(μ)
    model = StandardABM(
        TestAgent,
        space;
        properties = CDA(; n_markets, info_times),
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
```

## Run Model 

In the code block below, we will initialize the agent-based model for the prediction market and run the simulation for 50 days. The keywords are defined as follows:

- `n_agents`: the number of agents participating in the prediction market
- `μ`: a vector of mean beliefs sampled from a Dirichlet distribution
- `η`: the precision or inverse variance in the beliefs across agents 
- `money`: the size of each agent's budget in cents 
- `δ`: the variability in asks/bids in cents 

```@example example
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
```

## Plot Prices 

In the following code, we will plot the market prices as a function of time. Each line represents the market price for a different prediction market, which are down sampled to the final price each day. The black horizontal lines represent the expected market prices based on μ defined above. Notice that the market prices approximate the expected values. 

```@example example
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
```

## Plot Trade Volume 

The plot below shows trade volume computed as the sum of trades per day.

```@example example
trade_volume = summarize_by_iteration.(model.trade_counts, model.iteration_ids; fun = sum)

plot(
    trade_volume;
    layout = (2,2),
    grid = false,
    label = false,
    title = market_titles,
    ylims = (0, 100),
    plot_title = "Trade Volume"
)
```

## Plot Depth Chart

In the code block below, we plot the [depth chart](https://www.fusioncharts.com/blog/detailed-guide-on-how-to-read-a-depth-chart/) for each prediction market. 

```@example example
depth_charts = plot_depth_chart.(model.order_books)
plot(depth_charts...; layout = (2, 2), title = market_titles)
```

## Plot Autocorrelation

The plot below shows the autocorrelation between market prices for each prediction market. 
```@example example 
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
```

# Plot Dashboard

In the example below, we create an animated dashboard consisting of depth charts and market prices. 

```@example example 
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
```