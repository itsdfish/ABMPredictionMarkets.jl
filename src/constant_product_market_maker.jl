"""
    CPMM <: AbstractCPMM   

Holds reserves and data for a constant product market maker prediction market simulation.

# Fields 

- `yes_reserves::Vector{Float64}`: reserves for "yes" shares. Each element corresponds to a different market
- `no_reserves::Vector{Float64}`: reserves for "no" shares. Each element corresponds to a different market
- `market_prices::Vector{Vector{Float64}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market
- `info_times::Vector{Int}`: a vector of days on which new information is provided 
- `trade_counts::Vector{Vector{Int}}`: each elements represents the number of trades made per step
- `iteration_ids`::Vector{Vector{Int}}`: iteration number on which market prices are recorded

# Constructors
    
    CPMM(; yes_reserves, no_reserves)
"""
mutable struct CPMM <: AbstractCPMM
    yes_reserves::Vector{Float64}
    no_reserves::Vector{Float64}
    market_prices::Vector{Vector{Float64}}
    info_times::Vector{Int}
    trade_counts::Vector{Vector{Int}}
    iteration_ids::Vector{Vector{Int}}
end

function CPMM(; yes_reserves, no_reserves, info_times)
    n_markets = length(no_reserves)
    return CPMM(
        yes_reserves,
        no_reserves,
        init(Float64, n_markets),
        info_times,
        init(Int, n_markets),
        init(Int, n_markets)
    )
end

function get_price(market::AbstractCPMM, midx, yes)
    y = market.yes_reserves[midx]
    n = market.no_reserves[midx]
    # yes price goes up as n goes up and y goes down
    return yes ? n / (y + n) : y / (y + n)
end

function update_reserves!(market::AbstractCPMM, midx, n_shares, yes)
    new_y, new_n = get_new_reserves(market, midx, n_shares, yes)
    market.yes_reserves[midx] = new_y
    market.no_reserves[midx] = new_n
    return new_y, new_n
end

function get_new_reserves(market::AbstractCPMM, midx, n_shares, yes)
    y, n = get_reserves(market, midx)
    price = shares_to_cost(market, n_shares, y, n)
    return yes ? (y - n_shares + price, n + price) : (y + price, n - n_shares + price)
end

function shares_to_cost(::AbstractCPMM, n_shares, y, n)
    return (√((n - n_shares + y)^2 + 4 * n * n_shares) + n_shares - n - y) / 2
end

function shares_to_cost(market::AbstractCPMM, n_shares, midx)
    y, n = get_reserves(market, midx)
    return (√((n - n_shares + y)^2 + 4 * n * n_shares) + n_shares - n - y) / 2
end

get_reserves(market::AbstractCPMM, midx) =
    market.yes_reserves[midx], market.no_reserves[midx]

function cost_to_shares(market::AbstractCPMM, cost, midx)
    y, n = get_reserves(market, midx)
    return cost * (n + cost + y) / (n + cost)
end

function cost_to_shares(::AbstractCPMM, cost, n, y)
    return cost * (n + cost + y) / (n + cost)
end
