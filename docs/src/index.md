# PredictionMarketABM

This project contains an agent-based simulation of unpacking effects in prediction markets. 

```@raw html
<img src="assets/temp.gif" width=1200 height=800>
```
```@raw html
<details>
<summary><b>Show Details </b></summary>
```
```julia 
using Random
using Agents
using Plots
using PredictionMarketABM
Random.seed!(568)

n_agents = 200
model = initialize(
    CompatibleAgent;
    n_agents,
    μ = [0.20, 0.25, 0.10, 0.45],
    η = 20.0,
    money = 50000,
    δ = 3,
    info_times = Int[],
    n_markets = 5
)

animation = plot_dashboard(model)
gif(animation, "temp.gif", fps = 8)
```
```@raw html
</details>
```
