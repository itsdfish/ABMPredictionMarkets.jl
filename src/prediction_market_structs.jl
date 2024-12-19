abstract type AbstractOrder end

"""
    Order <: AbstractOrder

An object representing a bid, ask, or share. 

# Fields 

- `id::Int`: agent id 
- `yes::Bool`: true if represents a `yes` share 
- `price::Int`: the price of the share, price ∈ [0,100]
- `type::Symbol`: object type type ∈ [bid,ask,share]

# Constructors 

    Order(id, yes, price, type)

    Order(; id, yes, price, type)
"""
mutable struct Order <: AbstractOrder
    id::Int
    yes::Bool
    price::Int
    type::Symbol
end

Order(; id, yes, price, type) = Order(id, yes, price, type)

abstract type AbstractPredictionMarket end

"""
    DoubleContinuousAuction <: AbstractPredictionMarket   

Holds data and order book for prediction market simulation.

# Fields 

- `order_books::Vector{Vector{Order}}`: outstanding orders (bids and asks). Each sub-vector corresponds to a different market
- `market_prices::Vector{Vector{Float64}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market
- `info_times::Vector{Int}`: 
- `info_times::Vector{Int}`: a vector of days on which new information is provided 
- `trade_made::Vector{Vector{Bool}}`: on each agent step, indicates whether a trade was made

# Constructors
    
    DoubleContinuousAuction(; order_book, market_prices)
"""
mutable struct DoubleContinuousAuction <: AbstractPredictionMarket
    order_books::Vector{Vector{Order}}
    market_prices::Vector{Vector{Float64}}
    info_times::Vector{Int}
    trade_made::Vector{Vector{Bool}}
end

function DoubleContinuousAuction(; n_markets, info_times)
    return DoubleContinuousAuction(
        init(Order, n_markets),
        init(Float64, n_markets),
        info_times,
        init(Bool, n_markets)
    )
end
