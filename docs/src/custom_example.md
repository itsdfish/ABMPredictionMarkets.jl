# Custom Example 

The purpose of this tutorial is to demonstrate how to create an agent with custom behavior. The example below consists of two agent types: 

1. `subadditive agent`: an agent whose beliefs about a set of prediction markets are subadditive (i.e., exceeds 1), and thus violate probability theory.
2. `arbitrage agent`: an agent who exploits subadditive markets by purchasing *no shares* in each market.

Our example will demonstrate the value of arbitrage in correcting prices by comparing two conditions: (1) a *no arbitrage condition* consisting of 100 subadditive agents and zero arbitrage agents, and (2) an *arbitrage condition* consisting of 70 subadditive agents and 30 arbitrage agents. In the *arbigtrage condition*, the arbitrage agents will reduce subadditivity by renormalizing the market prices. 

## Sub-Additivity 

In this section, we provide a more formal explanation of subadditivity. Suppose the sample space $\boldsymbol{\Omega}$ is partitioned into a set of mutually exclusive and exhaustive sub-events: $\boldsymbol{\Omega} = \{e_1,e_2, \dots, e_n\}$. According to probability theory, the probabilities must be additive:  

$p(e_1 \cup e_2 \cup \dots \cup e_n) = \sum_{e_i \in \boldsymbol{\Omega}} p(e_i) = 1$

In other words, the sum of the probabilities across all sub-events must sum to 1. This logic extends to prediction markets because the market price is interpreted as a crowd sourced probability estimate.  Below, we will create a set of binary prediction markets covering events in $\boldsymbol{\Omega}$: 

$\mathbf{M} = \{(e_1, \bar{e_1}),(e_2, \bar{e_2}), \dots, (e_n, \bar{e_n})\}.$ 

Each market consists of and event $e_i$ represented by *yes shares* and its complementary event $\bar{e_i}$ represented by *no shares*. If additivity is satisfied, the sum of *yes prices* should approximate 1 at each time point. 

Click on the ▶ icon to reveal a full version of the code.  

```@raw html
<details>
<summary><b>Full Code</b></summary>
```
```julia
using ABMPredictionMarkets
using ABMPredictionMarkets: get_market
using ABMPredictionMarkets: get_min_ask
using ABMPredictionMarkets: init
using ABMPredictionMarkets: transact!
using Agents
using Plots
using Statistics
import ABMPredictionMarkets: agent_step!

@agent struct SubadditiveAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Int}
    δ::Int
    money::Int
    bid_reserve::Int
    max_quantity::Int
    shares::Vector{Vector{Order}}
end

@agent struct ArbitrageAgent(NoSpaceAgent) <: MarketAgent
    money::Int
    bid_reserve::Int
    shares::Vector{Vector{Order}}
end


@multiagent MultiAgent(ArbitrageAgent, SubadditiveAgent) <: MarketAgent

function agent_step!(agent, ::ArbitrageAgent, ::AbstractPredictionMarket, model)
    no_prices = get_no_prices(model)
    cost, win = eval_arbitrage(no_prices, 0)
    if (cost < win) && (agent.money ≥ cost)
        for bidx ∈ 1:length(model.order_books)
            order = Order(;id = agent.id, yes = false, price = no_prices[bidx], quantity = 1, type = :bid)
            transact!(order, model, bidx)
        end
    else
        for bidx ∈ 1:length(model.order_books) 
            push!(model.trade_counts[bidx], 0)
            push!(model.iteration_ids[bidx], abmtime(model))
            market_prices = model.market_prices[bidx]
            isempty(market_prices) ? push!(market_prices, NaN) :
            push!(market_prices, market_prices[end])
        end
    end
    return nothing
end

function eval_arbitrage(no_prices, fee_percent)
    n_win = length(no_prices) - 1
    win = n_win * 100
    cost = sum(no_prices)
    fees = sum(compute_fee.(fee_percent, sort(no_prices[1:n_win])))
    return (;cost, win = win - fees)
end

compute_fee(fee_percent, price) = fee_percent * min(price, 100 - price) * (100 / price)

function get_no_prices(model)
    return get_min_ask.(model.order_books; yes = false)
end

function initialize(
    standard_type::Type{<:SubadditiveAgent},
    arbitrage_type::Type{<:ArbitrageAgent};
    n_subadditive,
    n_arbitrage,
    μ,
    η,
    δ,
    money,
    max_quantity = 1,
    unpacking_factor,
    info_times = Int[]
)
    space = nothing
    n_markets = length(μ)
    model = StandardABM(
        MultiAgent,
        space;
        properties = CDA(; n_markets, info_times),
        agent_step!,
        scheduler = Schedulers.Randomly()
    )
    id = 0
    for _ ∈ 1:n_subadditive
        id += 1
        judgments = Int.(round.(rand(DiscreteDirichlet(μ, η)) * unpacking_factor))
        agent = (MultiAgent ∘ standard_type)(;
            id,
            judgments,
            money,
            bid_reserve = 0,
            δ,
            max_quantity,
            shares = init(Order, n_markets)
        )
        add_agent!(agent, model)
    end
    for _ ∈ 1:n_arbitrage
        id += 1
        agent = (MultiAgent ∘ arbitrage_type)(;
            id,
            money,
            bid_reserve = 0,
            shares = init(Order, n_markets)
        )
        add_agent!(agent, model)
    end
    return model
end

Random.seed!(5064)

config = (
    μ = [0.45, 0.20, 0.25, 0.10],
    η = 20.0,
    unpacking_factor = 1.3,
    δ = 3,
    money = 5000,
    max_quantity = 1,
)

no_arbitrage_model = initialize(
    SubadditiveAgent,
    ArbitrageAgent;
    n_subadditive = 100,
    n_arbitrage = 0,
    config...
)

arbitrage_model = initialize(
    SubadditiveAgent,
    ArbitrageAgent;
    n_subadditive = 70,
    n_arbitrage = 30,
    config...
)

run!(no_arbitrage_model, 100)
run!(arbitrage_model, 100)

no_arbitrage_market_prices = summarize_by_iteration.(no_arbitrage_model.market_prices, no_arbitrage_model.iteration_ids)

plot(
    sum(no_arbitrage_market_prices),
    ylims = (0, 2),
    xlabel = "Day", 
    ylabel = "Unpacking Factor",
    grid = false,
    label = "No Arbitriage",
)
hline!([1], color = :black, linestyle = :dash, label = nothing)

arbitrage_market_prices = summarize_by_iteration.(arbitrage_model.market_prices, arbitrage_model.iteration_ids)
plot!(sum(arbitrage_market_prices), label = "Arbitriage")
```
```@raw html
</details>
```

## Load Dependencies

Our first step is to load the required dependencies for simulation and plotting. In addition, we will import the function `agent_step!` so we can create a new method defining the behavior of the subadditive agent. 

```@example advanced_example 
using ABMPredictionMarkets
using ABMPredictionMarkets: get_market
using ABMPredictionMarkets: get_min_ask
using ABMPredictionMarkets: init
using ABMPredictionMarkets: transact!
using Agents
using Plots
using Statistics
import ABMPredictionMarkets: agent_step!
```

## Define Agents 

Below, we define agent types which is are subtype of `MarketAgent`. 

### Subadditive Agents

As the name implies, the probability judgments of the subadditive agent are subadditive. The subadditive agent has the following fields:

- `judgments::Vector{Int}`: a vector of probabilities for each event expressed in cents, which sum to a value greater than 100 because they are subadditive. 
- `δ::Int`: the degree of variability in bids and asks expressed in cents. 
- `money::Int`: the amount of money available to the agent expressed in cents. 
- `bid_reserve::Int`: the amount of money reserved for bids in the order book for ensuring sufficient funds
- `max_quantity::Int` the maximum quantity of shares per order
- `shares::Vector{Vector{Order}}`: a constaining for storing the shares owned by the agent. Each sub-vector corresponds to a shares for a sub-event. 

On each simulated day when the function `agent_step!` is called for a subadditive agent, it submits a bid or ask in each available market. Roughly speaking, it accepts the maximum bid or minimum ask if it is advantageous. Otherwise, it submits an order for an ask or bid with uniform variable and a range of $\delta$ cents. 

```@example advanced_example 
@agent struct SubadditiveAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Int}
    δ::Int
    money::Int
    bid_reserve::Int
    max_quantity::Int
    shares::Vector{Vector{Order}}
end
```

### Arbitrage Agent 

The goal of the arbitrage agent is to exploit sub-additive prices by purchacing *no* shares for all markets. Using this strategy guarantees a payout of 1 dollar for $n-1$ shares, i.e., all shares except the share whose complementary event occured. Assuming prices are sub-additive (i.e., $\sum_{i=1}^n e_i< 1$), then the cost of *no* shares for all markets, *c*,  must be less than the payout: $c < n - 1$. 

```@raw html
<details>
<summary><b>Mathematical Details</b></summary>
```
To see why, note the cost $c$ is

$c = \sum_{i=1}^n \bar{e}_i$
$c = \sum_{i=1}^n 1 - e_i$
$c = \sum_{i=1}^n 1 - \sum_{i=1}^n e_i$
$c = n - \sum_{i=1}^n e_i.$

Substituting $n - \sum_{i=1}^n e_i$ into $c < n-1$, we have

$n - \sum_{i=1}^n e_i < n - 1$
$\sum_{i=1}^n e_i > 1,$
which is consistent with our assumption of sub-additivity.
```@raw html
</details>
```

The arbitrage agent has a subset of fields defined above for the subadditive agent. 

```@example advanced_example 
@agent struct ArbitrageAgent(NoSpaceAgent) <: MarketAgent
    money::Int
    bid_reserve::Int
    shares::Vector{Vector{Order}}
end
```

### Multi-Agent

To improve performance, we will wrap the two agent types into a `MultiAgent` type with the `@multiagent` macro.

```@example advanced_example 
@multiagent MultiAgent(ArbitrageAgent, SubadditiveAgent) <: MarketAgent
```
## Agent Step Function 

The behavior of the arbitrage agent in the `agent_step!` method below. The function works as follows. First, the agent determines whether it can exploit subadditive prices. Second, if it can, it submits an order for a *no share* in each market. Otherwise, it records the previous market price as the current market price. 

```@example advanced_example 
function agent_step!(agent, ::ArbitrageAgent, ::AbstractPredictionMarket, model)
    no_prices = get_no_prices(model)
    cost, win = eval_arbitrage(no_prices, 0)
    if (cost < win) && (agent.money ≥ cost)
        for bidx ∈ 1:length(model.order_books)
            order = Order(;id = agent.id, yes = false, price = no_prices[bidx], quantity = 1, type = :bid)
            transact!(order, model, bidx)
        end
    else
        for bidx ∈ 1:length(model.order_books) 
            push!(model.trade_counts[bidx], 0)
            push!(model.iteration_ids[bidx], abmtime(model))
            market_prices = model.market_prices[bidx]
            isempty(market_prices) ? push!(market_prices, NaN) :
            push!(market_prices, market_prices[end])
        end
    end
    return nothing
end
```

## Arbitrage Functions

The code block defines three helper functions for arbitrage. Given a vector of *no prices* and a free percent, the function `eval_arbitrage` returns the cost and the payout for buying *no shares* in each prediction market. The function `compute_fee` returns the fees Polymarket applies to winnings. In our example, we assume for simplicity that the fee is zero percent. Finally, the function `get_all_no_prices` returns a vector of asking prices for *no shares* in each market. 

```@example advanced_example 
function eval_arbitrage(no_prices, fee_percent)
    n_win = length(no_prices) - 1
    win = n_win * 100
    cost = sum(no_prices)
    fees = sum(compute_fee.(fee_percent, sort(no_prices[1:n_win])))
    return (;cost, win = win - fees)
end

compute_fee(fee_percent, price) = fee_percent * min(price, 100 - price) * (100 / price)

function get_no_prices(model)
    return get_min_ask.(model.order_books; yes = false)
end
```

## Model Initialization Function 

In the code block below, we define a function that initializes the model and adds agents to the newly created model. The model has no spatial component because agents do not need to move in their environment. The model uses a type of prediction market called a continuous double action (see the type `CDA`). In addition, the scheduler randomizes the order in each agents perform their actions on each day. The function requires the following keyword arguments:

- `n_subadditive`: the number of subadditive agents in the simulation
- `n_arbitrage`: the number of arbitrage agents in the simulation
- `μ`: the mean probability judgments sampled from a Dirichlet distribution
- `η`: the precession of probability judgments sampled from a Dirichlet distribution
- `δ::Int`: the degree of variability in bids and asks expressed in cents. 
- `money`: the initial amount of money given to each agent
- `max_quantity = 1`: the maximum number of shares per order for each agent per day
- `unpacking_factor`: controls the degree of subadditivity in the judgments of the subadditive agents
- `info_times = Int[]`: required keyword argument that is not needed for this model

```@example advanced_example 
function initialize(
    standard_type::Type{<:SubadditiveAgent},
    arbitrage_type::Type{<:ArbitrageAgent};
    n_subadditive,
    n_arbitrage,
    μ,
    η,
    δ,
    money,
    max_quantity = 1,
    unpacking_factor,
    info_times = Int[]
)
    space = nothing
    n_markets = length(μ)
    model = StandardABM(
        MultiAgent,
        space;
        properties = CDA(; n_markets, info_times),
        agent_step!,
        scheduler = Schedulers.Randomly()
    )
    id = 0
    for _ ∈ 1:n_subadditive
        id += 1
        judgments = Int.(round.(rand(DiscreteDirichlet(μ, η)) * unpacking_factor))
        agent = (MultiAgent ∘ standard_type)(;
            id,
            judgments,
            money,
            bid_reserve = 0,
            δ,
            max_quantity,
            shares = init(Order, n_markets)
        )
        add_agent!(agent, model)
    end
    for _ ∈ 1:n_arbitrage
        id += 1
        agent = (MultiAgent ∘ arbitrage_type)(;
            id,
            money,
            bid_reserve = 0,
            shares = init(Order, n_markets)
        )
        add_agent!(agent, model)
    end
    return model
end
```

### Set RNG Seed
The next code block sets the seed for the random number generator to ensure the results are reproducible. 
```@example advanced_example
Random.seed!(5064)
```

## Initialize Models

In this section, we create models for the *no arbitrage condition* and the *arbitrage condition* with the function called `initialize`. The code block below defines a `NamedTuple` of the common parameters for each model. 

```@example advanced_example
config = (
    μ = [0.45, 0.20, 0.25, 0.10],
    η = 20.0,
    unpacking_factor = 1.3,
    δ = 3,
    money = 5000,
    max_quantity = 1,
)
```

### No Arbitrage Model

The defining feature of the *no arbitrage model* is the absence of arbitrage agents. Specifically, we set the number of subadditive agents to 100 and the number of arbitrage agents to 0. 

```@example advanced_example 
no_arbitrage_model = initialize(
    SubadditiveAgent,
    ArbitrageAgent;
    n_subadditive = 100,
    n_arbitrage = 0,
    config...
)
```


### Arbitrage Model

By contrast, the *arbitrage model* does include arbitrage agents. Specifically, we set the number of subadditive agents to 70 and the number of arbitrage agents to 30. 

```@example advanced_example 
arbitrage_model = initialize(
    SubadditiveAgent,
    ArbitrageAgent;
    n_subadditive = 70,
    n_arbitrage = 30,
    config...
)
```

## Run Models 

In the code block below, we run each model for 100 days. Agents sequentially perform their actions in a different random order each day. 

```@example advanced_example 
run!(no_arbitrage_model, 100)
run!(arbitrage_model, 100)
```

## Plot Results

In the plot below, we plot the ending market price each day for the *no arbitrage* and *arbitrage* models. As expected, both models show evidence of subadditivity (i.e., the data points are above 1), but the degree of subadditivity is less pronounced in the arbitrage model, indicating arbitrage agents were able to exploit the mispriced markets and partially correct the prices.

```@example advanced_example 
no_arbitrage_market_prices = summarize_by_iteration.(no_arbitrage_model.market_prices, no_arbitrage_model.iteration_ids)
plot(
    sum(no_arbitrage_market_prices),
    ylims = (0, 2),
    xlabel = "Day", 
    ylabel = "Unpacking Factor",
    grid = false,
    label = "No Arbitriage",
)
hline!([1], color = :black, linestyle = :dash, label = nothing)
arbitrage_market_prices = summarize_by_iteration.(arbitrage_model.market_prices, arbitrage_model.iteration_ids)
plot!(sum(arbitrage_market_prices), label = "Arbitriage")
```
