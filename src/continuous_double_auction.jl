"""
    CDA <: AbstractCDA   

Holds data and order book for a continuous double auction prediction market simulation.

# Fields 

- `order_books::Vector{Vector{Order}}`: outstanding orders (bids and asks). Each sub-vector corresponds to a different market
- `market_prices::Vector{Vector{Float64}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market
- `info_times::Vector{Int}`: 
- `info_times::Vector{Int}`: a vector of days on which new information is provided 
- `trade_made::Vector{Vector{Bool}}`: on each agent step, indicates whether a trade was made
- `iteration_ids`::Vector{Vector{Int}}`: iteration number on which market prices are recorded

# Constructors
    
    CDA(; order_book, market_prices)
"""
mutable struct CDA <: AbstractCDA
    order_books::Vector{Vector{Order}}
    market_prices::Vector{Vector{Float64}}
    info_times::Vector{Int}
    trade_made::Vector{Vector{Bool}}
    iteration_ids::Vector{Vector{Int}}
end

function CDA(; n_markets, info_times)
    return CDA(
        init(Order, n_markets),
        init(Float64, n_markets),
        info_times,
        init(Bool, n_markets),
        init(Int, n_markets)
    )
end

"""
    create_order(agent::MarketAgent, ::Type{<:AbstractCDA}, model, bidx)

Creates and returns a bid or ask. The function `bid` is called if the agent has no shares. The function `ask`
is called if the agent has no money. If the agent has money and shares, `bid` and `ask` are called with equal probability. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:AbstractCDA}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function create_order(agent::MarketAgent, ::Type{<:AbstractCDA}, model, bidx)
    if can_bid(agent) && can_ask(agent, bidx)
        return rand() ≤ 0.50 ? bid(agent, model, bidx) : ask(agent, model, bidx)
    elseif can_bid(agent) && !can_ask(agent, bidx)
        return bid(agent, model, bidx)
    elseif !can_bid(agent) && can_ask(agent, bidx)
        return ask(agent, model, bidx)
    else
        return Order(; id = 0, yes = true, price = 0, type = :empty)
    end
end

"""
    bid(agent::MarketAgent, ::Type{<:AbstractCDA}, model, bidx)

Generates an ask amount according to

`v ~ Uniform(p - δ, p, - 1)`,

where `p` is the agent's subject probability of the event. The bid price is subtracted from 
money and added to the bid reserve to ensure the agent has sufficient funds when making bids 
in multiple markets. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function bid(agent::MarketAgent, ::Type{<:AbstractCDA}, model, bidx)
    order_book = model.order_books[bidx]
    yes = rand(Bool)
    _, min_ask = get_market_info(order_book; yes)
    judgment = yes ? agent.judgments[bidx] : (100 - agent.judgments[bidx])
    price = judgment > min_ask ? min_ask : sample_bid(judgment, agent.δ)
    price = min(price, agent.money)
    agent.money -= price
    agent.bid_reserve += price
    return Order(; id = agent.id, yes, price, quantity = 1, type = :bid)
end

"""
    sample_bid(judgment, δ)

Samples an amount to ask.  

`v ~ Uniform(judgment, - δ, judgment - 1)`,

where `judgment` is the agent's subjective probability. 

# Arguments

- `judgment`: s the agent's subjective probability. judgment ∈ [0, 100]
- `δ`: the range of noise added to ask price. δ ≥ 1.  
"""
function sample_bid(judgment, δ)
    return max(
        rand(DiscreteUniform(judgment - δ, judgment - 1)),
        0
    )
end

"""
    ask(agent::MarketAgent, ::Type{<:AbstractCDA}, model, bidx)

Generates an ask amount according to 

`v ~ Uniform(p, + 1, p + δ)`,

where `p` is the maximum share price. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:AbstractCDA}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function ask(agent::MarketAgent, ::Type{<:AbstractCDA}, model, bidx)
    order_book = model.order_books[bidx]
    _, idx = findmax(x -> x.yes ? x.price : (100 - x.price), agent.shares[bidx])
    share = deepcopy(agent.shares[bidx][idx])
    share.quantity = 1
    share.type = :ask
    max_bid, _ = get_market_info(order_book; yes = share.yes)
    judgment = share.yes ? agent.judgments[bidx] : (100 - agent.judgments[bidx])
    # expected value for keeping the share 
    ev1 = judgment - share.price
    #expected value for sell at maximum bid 
    ev2 = max_bid - share.price
    share.price = ev2 > ev1 ? max_bid : sample_ask(judgment, agent.δ)
    return share
end

"""
    sample_ask(p, δ)

Samples an amount to ask.  

`v ~ Uniform(p, + 1, p + δ)`,

where `p` is typically the maximum share price. 

# Arguments

- `p`: is typically the maximum share price. p ∈ [0, 100]
- `δ`: the range of noise added to ask price. δ ≥ 1.  
"""
function sample_ask(p, δ)
    return min(
        rand(DiscreteUniform(p + 1, p + δ)),
        100
    )
end

function transact!(proposal, model, bidx)
    return transact!(proposal, get_market_type(model), model, bidx)
end

"""
    transact!(proposal, ::Type{<:AbstractCDA}, model, bidx)

Attempts to find a possible trade for a submitted proposal (bid or ask). Returns `true` if a 
trade was found and performed. Otherwise, `false` is returned. If no trade is performed, the proposal is added to 
the order book.

# Arguments

- `proposal`: a proposal bid or ask 
- `::Type{<:AbstractCDA}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function transact!(proposal, ::Type{<:AbstractCDA}, model, bidx)
    order_book = model.order_books[bidx]
    for i ∈ 1:length(order_book)
        bid_match!(proposal, model, bidx, i) ? (return true) : nothing
        ask_match!(proposal, model, bidx, i) ? (return true) : nothing
        ask_bid_match!(proposal, model, bidx, i) ? (return true) : nothing
    end
    market_prices = model.market_prices[bidx]
    push!(order_book, proposal)
    isempty(market_prices) ? push!(market_prices, NaN) :
    push!(market_prices, market_prices[end])
    return false
end

"""
    ask_bid_match!(proposal, model, bidx, i)

For agent `i` and agent `j`, let `b` be the bid amount, `a` be the ask amount, and `e` be the event.   
If `bₑᵢ = aₑⱼ`, then exchange. 

# Argument 

- `proposal`: a proposal bid or ask 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
- `i`: the index for the current entry of the order book 
"""
function ask_bid_match!(proposal, model, bidx, i)
    order = model.order_books[bidx][i]
    if can_exchange(proposal, order)
        buyer = proposal.type == :bid ? model[proposal.id] : model[order.id]
        seller = proposal.type == :ask ? model[proposal.id] : model[order.id]
        bid_order = proposal.type == :bid ? proposal : order
        ask_order = proposal.type == :ask ? proposal : order
        exchange!(buyer, seller, bid_order, ask_order, proposal, bidx)

        push!(
            model.market_prices[bidx],
            proposal.yes ? proposal.price / 100 : (100 - proposal.price) / 100
        )
        deleteat!(model.order_books[bidx], i)
        return true
    end
    return false
end

function can_exchange(proposal, order)
    if (order.yes == proposal.yes) && (order.type ≠ proposal.type) &&
       (order.id ≠ proposal.id)
        if (order.type == :bid) && (proposal.type == :ask) && (order.price ≥ proposal.price)
            return true
        elseif (order.type == :ask) && (proposal.type == :bid) &&
               (order.price ≤ proposal.price)
            return true
        end
    end
    return false
end

function exchange!(buyer, seller, bid_order, ask_order, proposal, bidx)
    # 3 at price = bid = 40 
    # 2 at ask = 30

    # 3 at bid = 40 
    # 2 at price = ask = 30
    price = proposal.price
    n_sold = min(bid_order.quantity, ask_order.quantity)
    total_cost = price * n_sold
    buyer.bid_reserve -= total_cost
    new_share =
        Order(; id = buyer.id, price, yes = bid_order.yes, quantity = n_sold, type = :share)
    push!(buyer.shares[bidx], new_share)

    ask_order.quantity -= n_sold
    seller.money += total_cost
    decrement_shares!(seller, proposal, n_sold, bidx)
    return nothing
end

function decrement_shares!(seller, proposal, n_sold, bidx)
    shares = filter(x -> x.yes == proposal.yes, seller.shares[bidx])
    sort!(shares; by = x -> x.price)
    i = 1
    n_accounted = 0
    removed_indices = Int[]
    while n_accounted ≠ n_sold
        share = shares[i]
        n_remove = min(n_sold, share.quantity)
        share.quantity -= n_remove
        if share.quantity == 0
            push!(removed_indices, findfirst(x -> x == share, seller.shares[bidx]))
        end
        n_accounted += n_remove
        i += 1
    end
    isempty(removed_indices) ? nothing : deleteat!(seller.shares[bidx], removed_indices)
    return nothing
end

"""
    bid_match!(proposal, model, bidx, i)

For agent `i` and agent `j`, let `b` be the bid amount, and `e` be the event.   
If `bₑᵢ + b¬ₑⱼ = 1`, then create new shares for `i` and `j`. 

# Argument 

- `proposal`: a proposal bid
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
- `i`: the index for the current entry of the order book 
"""
function bid_match!(proposal, model, bidx, i)
    order = model.order_books[bidx][i]
    if sums_to_100(proposal, order) && (order.yes ≠ proposal.yes) &&
       (order.type == proposal.type == :bid) && (order.id ≠ proposal.id)
        buyer1 = model[proposal.id]
        buyer2 = model[order.id]

        buyer1.bid_reserve -= proposal.price
        proposal.type = :share
        push!(buyer1.shares[bidx], proposal)

        buyer2.bid_reserve -= order.price
        order.type = :share
        push!(buyer2.shares[bidx], order)

        push!(
            model.market_prices[bidx],
            proposal.yes ? proposal.price / 100 : (100 - proposal.price) / 100
        )
        deleteat!(model.order_books[bidx], i)
        return true
    end
    return false
end

"""
    ask_match!(proposal, model, bidx, i)

For agent `i` and agent `j`, let `a` be the ask amount, and `e` be the event.   
If `aₑᵢ + a¬ₑⱼ = 1`, then remove shares and deduct ask amounts for `i` and `j` . 

# Argument 

- `proposal`: a proposal bid
- `model`: an abm object for the prediction market simulation 
- `i`: the index for the current entry of the order book 
"""
function ask_match!(proposal, model, bidx, i)
    order = model.order_books[bidx][i]
    if sums_to_100(proposal, order) && (order.yes ≠ proposal.yes) &&
       (order.type == proposal.type == :ask) && (order.id ≠ proposal.id)
        seller1 = model[proposal.id]
        seller2 = model[order.id]

        seller1.money += proposal.price
        shares = filter(x -> x.yes == proposal.yes, seller1.shares[bidx])
        _, idx = findmax(x -> x.price, shares)
        filter!(x -> x ≠ shares[idx], seller1.shares[bidx])

        seller2.money += order.price
        shares = filter(x -> x.yes == order.yes, seller2.shares[bidx])
        _, idx = findmax(x -> x.price, shares)
        filter!(x -> x ≠ shares[idx], seller2.shares[bidx])

        push!(
            model.market_prices[bidx],
            proposal.yes ? proposal.price / 100 : (100 - proposal.price) / 100
        )
        deleteat!(model.order_books[bidx], i)
        return true
    end
    return false
end

"""
    get_market_info(model; yes)

Returns the maximum bid and minimum ask in the order book. 

# Arguments

- `order_book`: a vector of outstanding orders

# Keywords

- `yes`: returns maximum bid and minimum ask for yes orders if true 
"""
function get_market_info(order_book; yes)
    return get_max_bid(order_book; yes), get_min_ask(order_book; yes)
end

function get_max_bid(order_book; yes)
    bids1 = filter(x -> (x.yes == yes) && (x.type == :bid), order_book)
    max_bid1, _ = isempty(bids1) ? (0.0, 0) : findmax(x -> x.price, bids1)

    bids2 = filter(x -> (x.yes ≠ yes) && (x.type == :ask), order_book)
    max_bid2, _ = isempty(bids2) ? (0.0, 0) : findmax(x -> (100 - x.price), bids2)
    return max(max_bid1, max_bid2)
end

function get_min_ask(order_book; yes)
    asks1 = filter(x -> (x.yes == yes) && (x.type == :ask), order_book)
    min_ask1, _ = isempty(asks1) ? (100, 0) : findmin(x -> x.price, asks1)

    asks2 = filter(x -> (x.yes ≠ yes) && (x.type == :bid), order_book)
    min_ask2, _ = isempty(asks2) ? (100, 0) : findmin(x -> (100 - x.price), asks2)
    return min(min_ask1, min_ask2)
end

sums_to_100(s1, s2) = (s1.price + s2.price) == 100

"""
    to_beta(μ, σ)

Returns α and β parameters of beta distribution corresponding to the desired mean and 
standard deviation. 

# Arguments

- `μ`: the desired mean of the beta distribution 
- `σ`: the desired standard deviation of the beta distribution
"""
function to_beta(μ, σ)
    x = μ * (1 - μ) / σ^2
    return μ * (x - 1), (1 - μ) * (x - 1)
end

init(T, n) = [T[] for _ ∈ 1:n]
