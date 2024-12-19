function find_trade!(proposal, model, bidx)
    return find_trade!(proposal, get_market_type(model), model, bidx)
end
"""
    find_trade!(proposal, ::Type{<:DoubleContinuousAuction}, model, bidx)

Attempts to find a possible trade for a submitted proposal (bid or ask). Returns `true` if a 
trade was found and performed. Otherwise, `false` is returned. If no trade is performed, the proposal is added to 
the order book.

# Arguments

- `proposal`: a proposal bid or ask 
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function find_trade!(proposal, ::Type{<:DoubleContinuousAuction}, model, bidx)
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

function ≠(s1::Order, s2::Order)
    for f ∈ fieldnames(Order)
        getproperty(s1, f) ≠ getproperty(s2, f) ? (return true) : nothing
    end
    return false
end

function ==(s1::Order, s2::Order)
    for f ∈ fieldnames(Order)
        getproperty(s1, f) ≠ getproperty(s2, f) ? (return false) : nothing
    end
    return true
end

init(T, n) = [T[] for _ ∈ 1:n]
