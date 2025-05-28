"""
    LSR <: AbstractLSR

An automated market maker using the logarithmic scoring rule.

# Fields 

- `elasticity`: elasticity parameter where higher values correspond to less elasticity
- `n_shares::Vector{Vector{Int}}`: each sub-vector corresponds to the number of shares for each option in a given market
- `market_prices::Vector{Vector{Vector{Float64}}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market at a different iteration. 
- `n_decimals::Int`: decimal places for rounding in favor of the automated market maker
- `trade_counts::Vector{Vector{Int}}`: each elements represents the number of trades made per step
- `iteration_ids`::Vector{Vector{Int}}`: iteration number on which market prices are recorded

# Constructors

    LSR(; elasticity, n_options, info_times)

# References

Berg, H., & Proebsting, T. A. (2009). Hanson’s automated market maker. The Journal of Prediction Markets, 3(1), 45-59.

Hanson, R. (2003). Combinatorial information market design. Information Systems Frontiers, 5, 107-119.
"""
mutable struct LSR <: AbstractLSR
    elasticity::Vector{Float64}
    n_shares::Vector{Vector{Float64}}
    market_prices::Vector{Vector{Vector{Float64}}}
    n_decimals::Int
    trade_counts::Vector{Vector{Float64}}
    iteration_ids::Vector{Vector{Int}}
end

function LSR(; elasticity, n_options)
    return LSR(
        elasticity,
        zeros.(n_options),
        init(Float64, length(n_options)),
        3,
        init(Float64, length(n_options)),
        init(Int, length(n_options))
    )
end

function agent_step!(agent, ::MarketAgent, market::AbstractLSR, model)
    market = abmproperties(model)
    n_markets = length(market.market_prices)
    for bidx ∈ shuffle(1:n_markets)
        prices = compute_prices(market, bidx)
        judgments = agent.judgments[bidx]
        diffs = abs.(judgments .- prices)
        for idx ∈ sortperm(diffs)
            cost = price_to_cost(market, judgments[idx], prices[idx], bidx)
            if cost ≥ 0
                n_shares = agent.shares[bidx][idx]
                share_value = shares_to_cost(market, prices[idx], -n_shares, bidx)
                amount = min(share_value, cost)
            else
                amount = max(cost, -agent.money)
            end
            n_shares = cost_to_shares(market, amount, prices[idx], bidx)
            order = LSROrder(; id = agent.id, n_shares, cost = amount, option = idx)
            transact!(order, market, model, bidx)
        end
    end
    return nothing 
end

function transact!(order, market::AbstractLSR, model, bidx)
    agent = model[order.id]
    idx = order.option
    agent.money += order.cost
    agent.shares[bidx][idx] += order.n_shares
    market.n_shares[bidx][idx] += order.n_shares
    prices = compute_prices(market, bidx)
    push!(model.market_prices[bidx], prices)
    push!(model.trade_counts[bidx], order.n_shares)
    push!(model.iteration_ids[bidx], abmtime(model))
    return nothing
end

function compute_prices(market::AbstractLSR, bidx)
    (; n_shares, elasticity) = market
    n = n_shares[bidx]
    b = elasticity[bidx]
    x = exp.(n / b)
    return x ./ sum(x)
end

"""
    set_elasticity(total_money, n_events, upper_price)

Sets the elasticity parameter to a value such that an upper price is achieved if all money 
    in a market allocated to a given event. 

# Arguments

- `total_money`: total money in a given market across all participants 
- `n_events`: the number of events that can be purchased in a given market
- `upper_price`: the maximum price, achieved if all money is placed on a single event
"""
function set_elasticity(total_money, n_events, upper_price)
    x = log(n_events * (1 - upper_price) / (n_events - 1))
    return -total_money / x
end

"""
    shares_to_cost(price, n_shares, elasticity)    

Finds the cost given a number of shares and current price. 

# Arguments 

- `price`: the current price of a given share
- `n_shares`: the number of shares purchased
- `elasticity`: the elasticity parameter
"""
function shares_to_cost(market::AbstractLSR, price, n_shares, bidx)
    (; elasticity) = market
    return -elasticity[bidx] * log(price * (exp(n_shares / elasticity[bidx]) - 1) + 1)
end

"""
    shares_to_price(price, n_shares, elasticity)   

Finds the new price given a number of shares and current price. 

# Arguments 

- `price`: the current price of a given share
- `n_shares`: the number of shares purchased
- `elasticity`: the elasticity parameter
"""
function shares_to_price(market::AbstractLSR, price, n_shares, bidx)
    (; elasticity) = market
    return 1 / (1 + (1 / price - 1) / exp(n_shares / elasticity[bidx]))
end

"""
    price_to_shares(new_price, price, elasticity)   

Finds the number of shares needed to change to a new price. 

# Arguments 

- `new_price`: the new price after purchacing shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
function price_to_shares(market::AbstractLSR, new_price, price, bidx)
    (; elasticity) = market
    return elasticity[bidx] * log((new_price * (1 - price)) / (price * (1 - new_price)))
end

"""
    price_to_cost(new_price, price, elasticity)  

Finds the number of shares needed to change to a new price. 

# Arguments 

- `new_price`: the new price after purchacing shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
function price_to_cost(market::AbstractLSR, new_price, price, bidx)
    (; elasticity) = market
    return -elasticity[bidx] * log((1 - price) / (1 - new_price))
end

"""
    cost_to_shares(cost, price, elasticity) 

Finds the number of shares that can be purchased at a given total cost. 

# Arguments 

- `cost`: the toal dollar amount of an exchange of shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
function cost_to_shares(market::AbstractLSR, cost, price, bidx)
    elasticity = market.elasticity[bidx]
    return elasticity * log(((exp(-cost / elasticity) - 1) / price) + 1)
end

"""
    cost_to_price(cost, price, elasticity) 

Finds the total cost of a transaction to move the current price to a new price. 

# Arguments 

- `cost`: the total dollar amount of an exchange of shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
function cost_to_price(market::AbstractLSR, cost, price, bidx)
    elasticity = market.elasticity[bidx]
    return 1 - (1 - price) / exp(-cost / elasticity)
end
