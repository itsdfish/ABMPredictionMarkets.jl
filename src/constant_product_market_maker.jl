"""
    CPMM <: AbstractCPMM   

Holds reserves and data for a constant product market maker prediction market simulation.

# Fields 

- `yes_reserves::Vector{Float64}`: reserves for "yes" shares. Each element corresponds to a different market
- `no_reserves::Vector{Float64}`: reserves for "no" shares. Each element corresponds to a different market
- `market_prices::Vector{Vector{Float64}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market
- `trade_counts::Vector{Vector{Int}}`: each elements represents the number of trades made per step
- `iteration_ids`::Vector{Vector{Int}}`: iteration number on which market prices are recorded

# Constructors
    
    CPMM(; yes_reserves, no_reserves)
"""
mutable struct CPMM <: AbstractCPMM
    yes_reserves::Vector{Float64}
    no_reserves::Vector{Float64}
    market_prices::Vector{Vector{Float64}}
    trade_counts::Vector{Vector{Int}}
    iteration_ids::Vector{Vector{Int}}
end

function CPMM(; yes_reserves, no_reserves)
    n_markets = length(no_reserves)
    return CPMM(
        yes_reserves,
        no_reserves,
        init(Float64, n_markets),
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

function update_reserves!(market::AbstractCPMM, midx, n_shares, cost, yes)
    new_y, new_n = update_reserves(market, midx, n_shares, cost, yes)
    market.yes_reserves[midx] = new_y
    market.no_reserves[midx] = new_n
    return new_y, new_n
end

function update_reserves(market::AbstractCPMM, midx, n_shares, cost, yes)
    y, n = get_reserves(market, midx)
    return yes ? (y - n_shares + cost, n + cost) : (y + cost, n - n_shares + cost)
end

"""
    shares_to_cost(market::AbstractCPMM, n_shares, midx)

Computes the total cost associated with a given number of shares of shares. 

# Arguments 

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `n_shares`: the number of shares
- `midx`: market index
"""
function shares_to_cost(market::AbstractCPMM, n_shares, midx, yes::Bool)
    y, n = get_reserves(market, midx)
    if yes 
        return -0.5 * (-sqrt(n_shares^2 + 2*n_shares*(n - y) + (n+y)^2) - n_shares + n + y)
    else
        return -0.5 * (-sqrt(n_shares^2 + 2*n_shares*(y - n) + (n+y)^2) - n_shares + n + y)
    end
    #return (√((n - n_shares + y)^2 + 4 * n * n_shares) + n_shares - n - y) / 2
end

function shares_to_cost(::AbstractCPMM, n_shares, y, n)
    return (√((n - n_shares + y)^2 + 4 * n * n_shares) + n_shares - n - y) / 2
end

function price_to_cost(market::AbstractCPMM, new_price, midx, yes)
    y, n = get_reserves(market, midx)
    D = new_price - get_price(market, midx, yes)
    numerator =
        -√(max(0, -D^2 * n^3 * y - 2 * D^2 * n^2 * y^2 - D^2 * n * y^3 - D * n^3 * y +
           D * n * y^3 + n^2 * y^2)) - D * n^2 - D * n * y + n * y
    denominator = D*n + D*y - y
    println("numerator $numerator denominator $denominator D $D n $n y $y")
    cost = numerator / denominator
    return cost
end

"""
    get_reserves(market::AbstractCPMM, midx)

Returns the liquidity reserves for a given market.

# Arguments 

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `midx`: market index

# Returns 

- `reserves::Tuple`: yes reserves, no reserves
"""
get_reserves(market::AbstractCPMM, midx) =
    market.yes_reserves[midx], market.no_reserves[midx]

"""
    cost_to_shares(market::AbstractCPMM, cost, midx)

Computes the number of shares required to achieve a given cost. 

# Arguments 

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `cost`: the cost of the shares
- `midx`: market index
"""
function cost_to_shares(market::AbstractCPMM, cost, midx, yes::Bool)
    y, n = get_reserves(market, midx)
    denom = yes ? (n + cost) : (y + cost)
    return cost * (n + cost + y) / denom
end

function cost_to_shares(::AbstractCPMM, cost, n, y)
    return cost * (n + cost + y) / (y + cost)
end