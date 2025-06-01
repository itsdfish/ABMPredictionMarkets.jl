
Click on the ▶ icon to reveal a full version of the code.  

```@raw html
<details>
<summary><b>Full Code</b></summary>
```
```julia
using ABMPredictionMarkets
using ABMPredictionMarkets: compute_optimal_purchase
using ABMPredictionMarkets: compute_price
using ABMPredictionMarkets: cost_to_shares
using ABMPredictionMarkets: get_market
using ABMPredictionMarkets: get_min_ask
using ABMPredictionMarkets: get_reserves
using ABMPredictionMarkets: init
using ABMPredictionMarkets: price_to_cost
using ABMPredictionMarkets: shares_to_cost
using ABMPredictionMarkets: update_reserves!
using ABMPredictionMarkets: transact!
using Agents
using Distributions
using Plots
using Random
using Revise
using Statistics
import ABMPredictionMarkets: agent_step!

@agent struct CPMMAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Vector{Float64}}
    money::Float64
    shares::Vector{Vector{Float64}}
    λ::Float64
end

function agent_step!(agent, ::CPMMAgent, market::AbstractCPMM, model)
    (; judgments, λ) = agent
    if agent.shares[1][1] > 0
        # sell yes shares
        n_shares = -agent.shares[1][1]
        cost = shares_to_cost(market, n_shares, 1, true)
        order = AMMOrder(; id = agent.id, option = true, cost, n_shares)
        transact!(order, market, model, 1)
        pop!(model.trade_volume[1])
        pop!(model.market_prices[1])
    end
    if agent.shares[1][2] > 0
        # sell no shares
        n_shares = -agent.shares[1][2]
        cost = shares_to_cost(market, n_shares, 1, false)
        order = AMMOrder(; id = agent.id, option = false, cost, n_shares)
        transact!(order, market, model, 1)
        pop!(model.trade_volume[1])
        pop!(model.market_prices[1])
    end

    price = compute_price(market, 1, true)
    belief = (1 - λ) * judgments[1][1] + λ * price
    if belief ≥ price
        # buy yes shares
        cost = compute_optimal_purchase(agent, market, belief, 1, true)
        n_shares = cost_to_shares(market, cost, 1, true)
        order = AMMOrder(; id = agent.id, option = true, cost, n_shares)
        transact!(order, market, model, 1)
    elseif belief < price
        # buy no shares
        cost = compute_optimal_purchase(agent, market, belief, 1, false)
        n_shares = cost_to_shares(market, cost, 1, false)
        order = AMMOrder(; id = agent.id, option = false, cost, n_shares)
        transact!(order, market, model, 1)
    end
    return nothing
end

function model_step!(model)
    agent = random_agent(model)
    agent_step!(agent, model)
    if abmtime(model) ∈ model.times
        market = get_market(model)
        current_price = compute_price(market, 1, true)
        target_price = min(1, current_price + 0.05)
        cost = price_to_cost(market, target_price, 1, true)
        n_shares = cost_to_shares(market, cost, 1, true)
        update_reserves!(market, n_shares, cost, 1, true)
        push!(model.trade_volume[1], n_shares)
        push!(model.market_prices[1], compute_price(market, 1, true))
    end
    return nothing
end

function initialize(
    agent_type::Type{<:CPMMAgent};
    n_agents,
    λ,
    money,
    yes_reserves,
    no_reserves,
    manipulate_time
)
    yes_reserves = deepcopy(yes_reserves)
    no_reserves = deepcopy(no_reserves)
    space = nothing
    model = StandardABM(
        agent_type,
        space;
        properties = CPMM(; yes_reserves, no_reserves, times = [manipulate_time]),
        model_step!,
        scheduler = Schedulers.Randomly()
    )
    for i ∈ 1:n_agents
        p = (i - 1) / (n_agents - 1)
        judgments = [[p, 1-p]]
        add_agent!(
            model;
            judgments,
            money,
            λ,
            shares = [zeros(2)]
        )
    end
    return model
end

config = (
    n_agents = 11,
    λ = 0.0,
    money = 100,
    no_reserves = [1000.0],
    yes_reserves = [1000.0],
    manipulate_time = 100,
)

market_prices = map(1:1000) do _
    model = initialize(CPMMAgent; config...)
    run!(model, 200)
    model.market_prices[1]
end

plot(
    mean(market_prices),
    ylims = (.4, .6),
    xlabel = "Day",
    ylabel = "Price of Yes Share",
    linewidth = 2.5,
    grid = false,
    leg = false,
)
hline!([.5], color = :black, linestyle = :dash)
```
```@raw html
</details>
```