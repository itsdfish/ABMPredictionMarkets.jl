"""
    DCA <: AbstractDCA   

Holds data and order book for a continuous double auction prediction market simulation.

# Fields 

- `order_books::Vector{Vector{Order}}`: outstanding orders (bids and asks). Each sub-vector corresponds to a different market
- `market_prices::Vector{Vector{Float64}}`: the market price in dollars after each interaction. The market price stays the same
    if a transaction does not occur. Each sub-vector corresponds to a different market
- `info_times::Vector{Int}`: 
- `info_times::Vector{Int}`: a vector of days on which new information is provided 
- `trade_made::Vector{Vector{Bool}}`: on each agent step, indicates whether a trade was made

# Constructors
    
    DCA(; order_book, market_prices)
"""
mutable struct DCA <: AbstractDCA
    order_books::Vector{Vector{Order}}
    market_prices::Vector{Vector{Float64}}
    info_times::Vector{Int}
    trade_made::Vector{Vector{Bool}}
end

function DCA(; n_markets, info_times)
    return DCA(
        init(Order, n_markets),
        init(Float64, n_markets),
        info_times,
        init(Bool, n_markets)
    )
end

"""
    create_order(agent::MarketAgent, ::Type{<:AbstractDCA}, model, bidx)

Creates and returns a bid or ask. The function `bid` is called if the agent has no shares. The function `ask`
is called if the agent has no money. If the agent has money and shares, `bid` and `ask` are called with equal probability. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:AbstractDCA}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function create_order(agent::MarketAgent, ::Type{<:AbstractDCA}, model, bidx)
    if can_bid(agent) && can_ask(agent, bidx)
        order = rand() ≤ 0.50 ? bid(agent, model, bidx) : ask(agent, model, bidx)
    elseif can_bid(agent) && !can_ask(agent, bidx)
        order = bid(agent, model, bidx)
    elseif !can_bid(agent) && can_ask(agent, bidx)
        order = ask(agent, model, bidx)
    end
    return order
end

"""
    bid(agent::MarketAgent, ::Type{<:AbstractDCA}, model, bidx)

Removes previous order and returns a bid. The bid amount is 

`v ~ Uniform(p - δ, p, - 1)`,

where `p` is the agent's subject probability of the event. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function bid(agent::MarketAgent, ::Type{<:AbstractDCA}, model, bidx)
    order_book = model.order_books[bidx]
    # remove old order
    filter!(x -> x.id ≠ agent.id, order_book)
    yes = rand(Bool)
    _, min_ask = get_market_info(order_book; yes)
    judgment = yes ? agent.judgments[bidx] : (100 - agent.judgments[bidx])
    price = judgment > min_ask ? min_ask : sample_bid(judgment, agent.δ)
    price = min(price, agent.money)
    return Order(; id = agent.id, yes, price, type = :bid)
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
    ask(agent::MarketAgent, ::Type{<:AbstractDCA}, model, bidx)

Removes previous order and returns an ask. The ask amount is 

`v ~ Uniform(p, + 1, p + δ)`,

where `p` is the maximum share price. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:AbstractDCA}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function ask(agent::MarketAgent, ::Type{<:AbstractDCA}, model, bidx)
    order_book = model.order_books[bidx]
    # remove previous order
    filter!(x -> x.id ≠ agent.id, order_book)
    _, idx = findmax(x -> x.price, agent.shares[bidx])
    share = deepcopy(agent.shares[bidx][idx])
    share.type = :ask
    max_bid, _ = get_market_info(order_book; yes = share.yes)
    share.price = max_bid > share.price ? max_bid : sample_ask(share.price, agent.δ)
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
    transact!(proposal, ::Type{<:AbstractDCA}, model, bidx)

Attempts to find a possible trade for a submitted proposal (bid or ask). Returns `true` if a 
trade was found and performed. Otherwise, `false` is returned. If no trade is performed, the proposal is added to 
the order book.

# Arguments

- `proposal`: a proposal bid or ask 
- `::Type{<:AbstractDCA}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function transact!(proposal, ::Type{<:AbstractDCA}, model, bidx)
    order_book = model.order_books[bidx]
    market_prices = model.market_prices[bidx]
    for i ∈ 1:length(order_book)
        bid_match!(proposal, model, bidx, i) ? (return true) : nothing
        ask_match!(proposal, model, bidx, i) ? (return true) : nothing
        ask_bid_match!(proposal, model, bidx, i) ? (return true) : nothing
    end
    push!(order_book, proposal)
    isempty(market_prices) ? push!(market_prices, NaN) :
    push!(market_prices, market_prices[end])
    return false
end

"""
    ask_bid_match!(proposal, model, i)

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
    if (order.price == proposal.price) && (order.yes == proposal.yes) &&
       (order.type ≠ proposal.type)
        buyer = proposal.type == :bid ? model[proposal.id] : model[order.id]
        seller = proposal.type == :ask ? model[proposal.id] : model[order.id]

        exchange!(buyer, seller, proposal, bidx)
        push!(
            model.market_prices[bidx],
            proposal.yes ? proposal.price / 100 : (100 - proposal.price) / 100
        )
        deleteat!(model.order_books[bidx], i)
        return true
    end
    return false
end

function exchange!(buyer, seller, proposal, bidx)
    buyer.money -= proposal.price
    proposal.type = :share
    proposal.id = buyer.id
    push!(buyer.shares[bidx], proposal)
    seller.money += proposal.price
    idx = findfirst(x -> x.yes == proposal.yes, seller.shares[bidx])
    deleteat!(seller.shares[bidx], idx)
    return nothing
end

"""
    bid_match!(proposal, model, i)

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
       (order.type == proposal.type == :bid)
        buyer1 = model[proposal.id]
        buyer2 = model[order.id]

        buyer1.money -= proposal.price
        proposal.type = :share
        push!(buyer1.shares[bidx], proposal)

        buyer2.money -= order.price
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
    ask_match!(proposal, model, i)

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
       (order.type == proposal.type == :ask)
        seller1 = model[proposal.id]
        seller2 = model[order.id]

        seller1.money += proposal.price
        idx = findfirst(x -> x.yes == proposal.yes, seller1.shares[bidx])
        deleteat!(seller1.shares[bidx], idx)

        seller2.money += order.price
        idx = findfirst(x -> x.yes == order.yes, seller2.shares[bidx])
        deleteat!(seller2.shares[bidx], idx)

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
