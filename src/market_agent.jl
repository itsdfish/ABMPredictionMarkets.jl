"""
    MarketAgent <: AbstractAgent

An agent that submits bids and asks in a prediction market. 
"""
abstract type MarketAgent <: AbstractAgent end

get_market_type(model) = typeof(abmproperties(model))

function create_order(agent::MarketAgent, model, bidx)
    return create_order(agent, get_market_type(model), model, bidx)
end

function bid(agent::MarketAgent, model, bidx)
    return bid(agent, get_market_type(model), model, bidx)
end

function ask(agent::MarketAgent, model, bidx)
    return ask(agent, get_market_type(model), model, bidx)
end

function agent_step!(agent::MarketAgent, model)
    return agent_step!(agent, get_market_type(model), model)
end

"""
    agent_step!(agent::MarketAgent, model)

The agent submits a new order for a bid or ask in each market. 
The order is checked against potential sellers (buyers), and 
an exchange is made if one is found. Otherwise, the order is added to the order book.    

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
"""
function agent_step!(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model)
    for bidx ∈ 1:length(model.order_books)
        order = create_order(agent, model, bidx)
        push!(model.trade_made[bidx], find_trade!(order, model, bidx))
    end
    return nothing
end

"""
    create_order(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model, bidx)

Creates and returns a bid or ask. The function `bid` is called if the agent has no shares. The function `ask`
is called if the agent has no money. If the agent has money and shares, `bid` and `ask` are called with equal probability. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function create_order(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model, bidx)
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
    bid(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model, bidx)

Removes previous order and returns a bid. The bid amount is 

`v ~ Uniform(p - δ, p, - 1)`,

where `p` is the agent's subject probability of the event. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function bid(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model, bidx)
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
    ask(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model, bidx)

Removes previous order and returns an ask. The ask amount is 

`v ~ Uniform(p, + 1, p + δ)`,

where `p` is the maximum share price. 

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `::Type{<:DoubleContinuousAuction}`: a double continuous auction prediction market type 
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function ask(agent::MarketAgent, ::Type{<:DoubleContinuousAuction}, model, bidx)
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

can_bid(agent::MarketAgent) = agent.money > 0
can_ask(agent::MarketAgent, bidx) = !isempty(agent.shares[bidx])

function add_info(agent::MarketAgent, model) end
