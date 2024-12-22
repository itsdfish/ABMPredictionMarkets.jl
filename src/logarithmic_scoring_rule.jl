mutable struct LogarithmicScoringRule <: AbstractPredictionMarket
    n_shares::Vector{Vector{Int}}
    market_prices::Vector{Vector{Float64}}
    current_prices::Vector{Vector{Float64}}
    n_decimals::Int
    info_times::Vector{Int}
    trade_made::Vector{Vector{Bool}}
end

"""
    create_order(agent::MarketAgent, ::Type{<:LogarithmicScoringRule}, model, bidx)

Creates and returns a bid or ask. The function `bid` is called if the agent has no shares. The function `ask`
is called if the agent has no money. If the agent has money and shares, `bid` and `ask` are called with equal probability. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:LogarithmicScoringRule}`: a LSR market maker type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function create_order(agent::MarketAgent, ::Type{<:LogarithmicScoringRule}, model, bidx)
    market = abmproperties(model)
    prices = compute_prices(market, bidx)
    judgments = agent.judgments[bidx]

    # prices = [0.60, 0.40]
    # judgments = [0.55, 0.45]

    return order
end

"""
    find_trade!(proposal, ::Type{<:DoubleContinuousAuction}, model, bidx)

Attempts to find a possible trade for a submitted proposal (bid or ask). Returns `true` if a 
trade was found and performed. Otherwise, `false` is returned. If no trade is performed, the proposal is added to 
the order book.

# Arguments

- `proposal`: a proposal bid or ask 
- `::Type{<:LogarithmicScoringRule}`: a LSR market maker type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function find_trade!(proposal, ::Type{<:LogarithmicScoringRule}, model, bidx)
    order_book = model.order_books[bidx]
    # for i ∈ 1:length(order_book)
    #     bid_match!(proposal, model, bidx, i) ? (return true) : nothing
    #     ask_match!(proposal, model, bidx, i) ? (return true) : nothing
    #     ask_bid_match!(proposal, model, bidx, i) ? (return true) : nothing
    # end
    isempty(market_prices) ? push!(market_prices, NaN) :
    push!(market_prices, market_prices[end])
    return false
end

function compute_prices(market::LogarithmicScoringRule, bidx)
    (; n_shares, elasticity) = market
    return compute_prices(n_shares[bidx], elasticity)
end

function compute_prices(n, b)
    x = exp.(n / b)
    return x ./ sum(x)
end

function shares_to_cost(market::LogarithmicScoringRule, bidx)
    (; prices, n_shares, elasticity) = market
    return shares_to_cost(prices[bidx], n_shares[bidx], elasticity)
end

"""
    shares_to_cost(prices, n_shares, elasticity)    

Finds the cost given a number of shares and current price. 

# Arguments 

- `price`: the current price of a given share
- `n_shares`: the number of shares purchaced
- `elasticity`: the elasticity parameter
"""
shares_to_cost(price, n_shares, elasticity) =
    -elasticity * log(price * (exp(n_shares / elasticity) - 1) + 1)

"""
    shares_to_price(price, n_shares, elasticity)   

Finds the new price given a number of shares and current price. 

# Arguments 

- `price`: the current price of a given share
- `n_shares`: the number of shares purchaced
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

"""
    cost_to_price(cost, price, elasticity) 

Finds the total cost of a transaction to move the current price to a new price. 

# Arguments 

- `cost`: the toal dollar amount of an exchange of shares
- `price`: the current price of a given share
- `elasticity`: the elasticity parameter
"""
cost_to_price(cost, price, elasticity) =
    1 - (1 - price) / exp(-cost / elasticity)