"""
    LSR <: AbstractLSR

A market maker using the logarithmic scoring rule.

# Fields 

- `elasticity`: elasticity parameter where higher values correspond to less elasticity
- `n_shares::Vector{Vector{Int}}`:
- `market_prices::Vector{Vector{Float64}}`:
- `n_decimals::Int`:
- `info_times::Vector{Int}`:
- `trade_made::Vector{Vector{Bool}}`:

# References

Berg, H., & Proebsting, T. A. (2009). Hanson’s automated market maker. The Journal of Prediction Markets, 3(1), 45-59.

Hanson, R. (2003). Combinatorial information market design. Information Systems Frontiers, 5, 107-119.
"""
mutable struct LSR <: AbstractLSR
    elasticity::Vector{Float64}
    n_shares::Vector{Vector{Float64}}
    market_prices::Vector{Vector{Vector{Float64}}}
    n_decimals::Int
    info_times::Vector{Int}
    trade_made::Vector{Vector{Bool}}
end

function LSR(; elasticity, n_options, info_times)
    return LSR(
        elasticity,
        zeros.(n_options),
        init(Float64, length(n_options)),
        3,
        info_times,
        init(Bool, length(n_options))
    )
end

function agent_step!(agent, ::MarketAgent, market::AbstractLSR, model)
    market = abmproperties(model)
    n_markets = length(market.market_prices)
    for bidx ∈ shuffle(1:n_markets)
        transact!(agent, market, model, bidx)
    end
    return nothing
end

function transact!(agent, market::AbstractLSR, model, bidx)
    prices = compute_prices(market, bidx)
    judgments = agent.judgments[bidx]
    diffs = judgments .- prices
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
        agent.money += amount
        agent.shares[bidx][idx] += n_shares
        market.n_shares[bidx][idx] += n_shares

        prices = compute_prices(market, bidx)
        push!(model.market_prices[bidx], prices)
    end
    return nothing
end

function compute_prices(market::AbstractLSR, bidx)
    (; n_shares, elasticity) = market
    return compute_prices(n_shares[bidx], elasticity[bidx])
end

function compute_prices(n, b)
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
    shares_to_cost(prices, n_shares, elasticity)    

Finds the cost given a number of shares and current price. 

# Arguments 

- `price`: the current price of a given share
- `n_shares`: the number of shares purchased
- `elasticity`: the elasticity parameter
"""
shares_to_cost(price, n_shares, elasticity) =
    -elasticity * log(price * (exp(n_shares / elasticity) - 1) + 1)

function shares_to_cost(market::AbstractLSR, price, n_shares, bidx)
    (; elasticity) = market
    return shares_to_cost(price, n_shares, elasticity[bidx])
end

"""
    shares_to_price(price, n_shares, elasticity)   

Finds the new price given a number of shares and current price. 

# Arguments 

- `price`: the current price of a given share
- `n_shares`: the number of shares purchased
- `elasticity`: the elasticity parameter
"""
shares_to_price(price, n_shares, elasticity) =
    1 / (1 + (1 / price - 1) / exp(n_shares / elasticity))

"""
    price_to_shares(new_price, price, elasticity)   

Finds the number of shares needed to change to a new price. 

# Arguments 

- `new_price`: the new price after purchacing shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
price_to_shares(new_price, price, elasticity) =
    elasticity * log((new_price * (1 - price)) / (price * (1 - new_price)))

"""
    price_to_cost(new_price, price, elasticity)  

Finds the number of shares needed to change to a new price. 

# Arguments 

- `new_price`: the new price after purchacing shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
price_to_cost(new_price, price, elasticity) =
    -elasticity * log((1 - price) / (1 - new_price))

function price_to_cost(market::AbstractLSR, new_price, price, bidx)
    price_to_cost(new_price, price, market.elasticity[bidx])
end

"""
    cost_to_shares(cost, price, elasticity) 

Finds the number of shares that can be purchased at a given total cost. 

# Arguments 

- `cost`: the toal dollar amount of an exchange of shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
cost_to_shares(cost, price, elasticity) =
    elasticity * log(((exp(-cost / elasticity) - 1) / price) + 1)

function cost_to_shares(market::AbstractLSR, cost, price, bidx)
    return cost_to_shares(cost, price, market.elasticity[bidx])
end

"""
    cost_to_price(cost, price, elasticity) 

Finds the total cost of a transaction to move the current price to a new price. 

# Arguments 

- `cost`: the total dollar amount of an exchange of shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
cost_to_price(cost, price, elasticity) =
    1 - (1 - price) / exp(-cost / elasticity)
