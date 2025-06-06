"""
    CPMM <: AbstractCPMM   

Holds reserves and data for a constant product market maker prediction market simulation.

# Fields 

- `yes_reserves::Vector{Float64}`: reserves for "yes" shares. Each element corresponds to a different market
- `no_reserves::Vector{Float64}`: reserves for "no" shares. Each element corresponds to a different market
- `market_prices::Vector{Vector{Float64}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market
- `trade_volume::Vector{Vector{Int}}`: each elements represents the number of trades made per step
- `iteration_ids`::Vector{Vector{Int}}`: iteration number on which market prices are recorded
- `times::Vector{Int} = Int[]`: times at which specific events may occur

# Constructors
    
    CPMM(; yes_reserves, no_reserves, times = Int[])
"""
mutable struct CPMM <: AbstractCPMM
    yes_reserves::Vector{Float64}
    no_reserves::Vector{Float64}
    market_prices::Vector{Vector{Float64}}
    trade_volume::Vector{Vector{Float64}}
    iteration_ids::Vector{Vector{Int}}
    times::Vector{Int}
end

function CPMM(; yes_reserves, no_reserves, times = Int[])
    n_markets = length(no_reserves)
    return CPMM(
        yes_reserves,
        no_reserves,
        init(Float64, n_markets),
        init(Float64, n_markets),
        init(Int, n_markets),
        times
    )
end

function transact!(order, market::AbstractCPMM, model, midx)
    agent = model[order.id]
    idx = order.option ? 1 : 2
    agent.money -= order.cost
    agent.shares[midx][idx] += order.n_shares
    update_reserves!(market, order.n_shares, order.cost, midx, order.option)
    price = compute_price(market, midx, true)
    push!(model.market_prices[midx], price)
    push!(model.trade_volume[midx], abs(order.n_shares))
    push!(model.iteration_ids[midx], abmtime(model))
    return nothing
end

"""
    compute_price(market::AbstractCPMM, midx, yes::Bool)

Returns the current price of the specified share. 

# Arguments 

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `midx`: market index
- `yes::Bool`: corresponds to a yes share if true; otherwise, corresponds to a no share
"""
function compute_price(market::AbstractCPMM, midx, yes::Bool)
    y = market.yes_reserves[midx]
    n = market.no_reserves[midx]
    # yes price goes up as n goes up and y goes down
    return yes ? n / (y + n) : y / (y + n)
end

"""
    update_reserves!(market::AbstractCPMM, n_shares, cost, midx, yes::Bool)

Updates the reserves given a transaction with a specified number of shares and total cost. 

# Arguments 

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `n_shares`: the number of shares
- `cost`: the total cost of the shares
- `midx`: market index
- `yes::Bool`: corresponds to a yes share if true; otherwise, corresponds to a no share
"""
function update_reserves!(market::AbstractCPMM, n_shares, cost, midx, yes::Bool)
    new_y, new_n = update_reserves(market, n_shares, cost, midx, yes)
    market.yes_reserves[midx] = new_y
    market.no_reserves[midx] = new_n
    return new_y, new_n
end

function update_reserves(market::AbstractCPMM, n_shares, cost, midx, yes)
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
- `yes::Bool`: corresponds to a yes share if true; otherwise, corresponds to a no share
"""
function shares_to_cost(market::AbstractCPMM, n_shares, midx, yes::Bool)
    reserves = get_reserves(market, midx)
    y, n = yes ? reserves : reserves[[2, 1]]
    return (√((n - n_shares + y)^2 + 4 * n * n_shares) + n_shares - n - y) / 2
end

function shares_to_cost(::AbstractCPMM, n_shares, y, n)
    return (√((n - n_shares + y)^2 + 4 * n * n_shares) + n_shares - n - y) / 2
end

"""
    price_to_cost(market::AbstractCPMM, target_price, midx, yes::Bool)

Computes the total cost required to achieve a target price. 

# Arguments 

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `target_price`: the desired price after transaction
- `midx`: market index
- `yes::Bool`: corresponds to a yes share if true; otherwise, corresponds to a no share
"""
function price_to_cost(market::AbstractCPMM, target_price, midx, yes::Bool)
    reserves = get_reserves(market, midx)
    y, n = yes ? reserves : reserves[[2, 1]]
    d = target_price - compute_price(market, midx, yes)
    cost =
        (-√(-d^2 * n^3 * y - 2 * d^2 * n^2 * y^2 - d^2 * n * y^3 - d * n^3 * y +
            d * n * y^3 + n^2 * y^2) - d * n^2 - d * n * y + n * y) / (d * n + d * y - y)
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
- `cost`: the total cost of the shares
- `midx`: market index
- `yes::Bool`: corresponds to a yes share if true; otherwise, corresponds to a no share
"""
function cost_to_shares(market::AbstractCPMM, cost, midx, yes::Bool)
    y, n = get_reserves(market, midx)
    denom = yes ? (n + cost) : (y + cost)
    return cost * (n + cost + y) / denom
end

"""
    compute_optimal_purchase(agent, market::CPMM, belief, midx, yes)

Computes the optimal amount of money to spend on shares based on a logarithmic utility function. 

#  Arguments

- `market::AbstractCPMM`: an abstract constant product market maker object 
- `cost`: the total cost of the shares
- `midx`: market index
- `yes::Bool`: corresponds to a yes share if true; otherwise, corresponds to a no share
"""
function compute_optimal_purchase(agent, market::CPMM, belief, midx, yes::Bool)
    (; money) = agent
    price = compute_price(market, midx, yes)
    belief == price ? (return 0.0) : nothing
    (belief == 1 && yes) || (belief == 0 && !yes) ? (return money) : nothing
    y, n = get_reserves(market, midx)
    if yes
        cost =
            (n * (y - 2 * (belief - 1) * money) - √(n * y *
               (n * (-4 * belief^2 * money + 4 * belief * money + y) -
                4 * (belief - 1) * belief * money * (money + y)))) /
            (2 * (belief - 1) * (money + y))
    else
        cost =
            (√(n * y *
               (n * (-4 * belief^2 * money + 4 * belief * money + y) -
                4 * (belief - 1) * belief * money * (money + y))) - n * y -
             2 * belief * money * y) / (2 * belief * (n + money))
    end
    return cost
end
