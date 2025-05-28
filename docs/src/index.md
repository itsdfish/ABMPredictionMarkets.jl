# ABMPredictionMarkets

This package provides an API built upon the [Agents.jl](https://juliadynamics.github.io/Agents.jl/stable/) framework for creating agent-based models of prediction markets. The package provides support for the following features:

* Default methods for processing transactions
* The ability to develop agents with custom behavior
* Different types of prediction markets, including continous double auctions and automated market makers
* Plotting and animations for time series, depth charts, autocorrelation, and trade volume charts

The animation below shows depth charts and time series of four prediction markets. The depth charts show outstanding bids in red and asks in blue in the order book. When an ask price and bid price match, a transaction occurs and the resulting price is updated in the time series plot below. 

```@raw html
<details>
<summary><b>Show Plotting Code </b></summary>
```
```julia 
using Random
using Agents
using Plots
using ABMPredictionMarkets
Random.seed!(568)

n_agents = 200
model = initialize(
    TestAgent;
    n_agents,
    μ = [0.20, 0.25, 0.10, 0.45],
    η = 20.0,
    money = 50000,
    δ = 3,
    n_markets = 5
)

animation = plot_dashboard(model)
gif(animation, "temp.gif", fps = 8)
```
```@raw html
</details>
```
```@raw html
<img src="assets/temp.gif" width=1200 height=800>
```
