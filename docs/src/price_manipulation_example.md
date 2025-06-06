# Price Manipulation Example 

Our goal in this example is to develop an agent based model of price manipulation in a prediction market as described in the arXiv paper entitled *How manipulable are prediction markets?* (Rasooly & Rozzi, 2025). In this example, a small set of agents trade shares in a prediction market based on a constant product market maker. During the trading period, a manipulator increases the current market price by .05 units. The model illustrates partial recovery of the market price, similar to what was found empirically in a large scale field experiment conducted by the authors (Rasooly & Rozzi, 2025).


If you prefer to skip the explanation below, click on the ▶ icon to reveal a full version of the code.  

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
using ABMPredictionMarkets: init
using ABMPredictionMarkets: price_to_cost
using ABMPredictionMarkets: shares_to_cost
using ABMPredictionMarkets: update_reserves!
using ABMPredictionMarkets: transact!
using Agents
using Distributions
using Plots
using Random
import ABMPredictionMarkets: agent_step!

@agent struct CPMMAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Vector{Float64}}
    money::Float64
    shares::Vector{Vector{Float64}}
    λ::Float64
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

## Load Dependencies

Our first step is to load the required dependencies for simulation and plotting. In addition, we will import the function `agent_step!` so we can create a new method defining the behavior of the agents in the price manipulation simulation.

```@example cpmm_example
using ABMPredictionMarkets
using ABMPredictionMarkets: compute_optimal_purchase
using ABMPredictionMarkets: compute_price
using ABMPredictionMarkets: cost_to_shares
using ABMPredictionMarkets: get_market
using ABMPredictionMarkets: init
using ABMPredictionMarkets: price_to_cost
using ABMPredictionMarkets: shares_to_cost
using ABMPredictionMarkets: update_reserves!
using ABMPredictionMarkets: transact!
using Agents
using Distributions
using Plots
using Random
import ABMPredictionMarkets: agent_step!
```

## CPMM Agent 

The code block below defines an agent type called *CPMMAgent*. In this agent type, the first three fields are required, and the fourth field is an optional parameter included for this specific simulation scenario. The fields are defined as follows:

* `judgements`: a vector of vectors in which elements of the outer vector represent individual prediction markets and elements of the inner vectors represent subjective price estimates of options of a given market. For example `judgements = [[.3,.7],[.2,.8]]` contains price estimates for two prediction markets and `[.3,.7]` represents the price estimates of the first and second options of the first prediction market. Currently, `CPMM` only supports binary prediction markets, but multiple prediction markets may be used within the same simulation. 
* `money`: the amount of money in dollars available to purchase shares.
* `shares`: a vector of vectors recording the number of shares the agent owns. Similar to the field `judgments` elements of the outer vector represent individual prediction markets and elements of inner vector represent different options within a prediction market. 
* `λ`: the weight given to an estimated price in `judgments` relative to the current market place, such that ``\lambda \in \left[0, 1 \right]``.  

```@example cpmm_example
@agent struct CPMMAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Vector{Float64}}
    money::Float64
    shares::Vector{Vector{Float64}}
    λ::Float64
end
```

## Constant Product Market Maker

The price manipulation simulation uses a type of prediction market called a constant product market maker (CPMM). A CPMM is a type of automated market maker which uses an algorithm ensure liquidity in a market and adjust the price of an asset based on demand. The price of a share in a CPMM is determined by the product of the amount of reserves for *yes* shares and *no* shares:

$r_y \cdot r_n = k,$

where $r_y$ and $r_n$ are the reserves for *yes* and *no* shares, respectively. Share prices are constrained such that the product of *yes* and *no* reserves must equal the constant $k$, as shown below:
```@raw html
<details>
<summary><b>Plot Code</b></summary>
```
```@example cpmm_example
reserve_plot = let 
    x = .01:.01:250
    y = 1000 ./ x 
    plot(x, y, xlabel = "Yes Reserves", ylabel = "No Reserves", lims = (0, 250), grid = false, leg = false)
end
nothing
```
```@raw html
</details>
```

```@example cpmm_example
reserve_plot
```
The price is computed as the ratio of reserves. For example, the price for a *yes* share is $\frac{r_n}{r_y + r_n}$.

## Model Step Function 

On each iteration of the simulation, the function `model_step!` is called, which performs the following actions:

1. Select a random agent and trade via the `agent_step!` function.
2. Manipulate the current price by $.05$ units at specified iterations. 

```@example cpmm_example
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
```

## Agent Step Function

The `agent_step!`, which is called in the `model_step!` function above, defines the trading behavior of the agents. `agent_step!` performs the following actions:

1. sell any available *yes* or *no* shares
2. define belief $b$ for price of *yes* shares as ``b = \lambda \cdot p + (1 - \lambda) \cdot j``, where ``p`` is the current price of a *yes* share and ``j`` is the estimated price. Buy yes if ``b \leq j``, buy no otherwise.

```@example cpmm_example
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
```

## Model Initialization Function 

The function specified in the code block below initializes the model using parameter values provided by the user. The model contains agents and a CPMM without a spatial component. The keyword arguments for the function are defined as follows: 

* `agent_type`: the agent type used in the simlation
* `n_agents`: the number of agents in the simulation
* `λ`: the price weight parameter
* `money`: the initial amount of money available for each agent to buy shares
* `yes_reserves`: the number of reserves for *yes* shares
* `no_reserves`: the number of reserves for *no* shares
* `manipulate_time`: the time at which the market is manipulated

The estimated price ranges from 0 to 1 across agents, such that the average estimate is .50.

```@example cpmm_example
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
```

## Set RNG Seed

In the code block below, we set the seed for the random number generator to ensure reproducible results. 

```@example cpmm_example
Random.seed!(5471)
```
## Configure Model 

In the `NamedTuple` below, we will set the values for the keyword arguments passed to the `initialize` function. The parameter values were selected to reproduce Figure 1 (a) reported in Rasooly & Rozzi (2025). 

```@example cpmm_example
config = (
    n_agents = 11,
    λ = 0.0,
    money = 100,
    no_reserves = [1000.0],
    yes_reserves = [1000.0],
    manipulate_time = 100,
)
```
## Simulate the Model

Now that we have defined the agents and the model parameters, we are in the position to simulate the model. The code below runs the model 1000 times and returns a vector of 200 market prices per run. 

```@example cpmm_example
market_prices = map(1:1000) do _
    model = initialize(CPMMAgent; config...)
    run!(model, 200)
    model.market_prices[1]
end
```

## Plot the Results 

The code block below plots the price as a function of time averaged across the 1000 simulations. The dashed line
denotes the expected price based on the beliefs of the agents. At day 100, a manipulator inflates the price by 5 cents. The true price shows a gradual, but partial recovery, which suggests that price manipulation can have an enduring effect. 

```@example cpmm_example
plot(
    mean(market_prices),
    ylims = (.39, .61),
    xlabel = "Day",
    ylabel = "Price of Yes Share",
    linewidth = 2.5,
    grid = false,
    leg = false,
)
hline!([.5], color = :black, linestyle = :dash)
```

## References

Rasooly, I., & Rozzi, R. (2025). How manipulable are prediction markets?. arXiv preprint arXiv:2503.03312.