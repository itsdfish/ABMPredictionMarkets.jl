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
- `::Type{<:AbstractPredictionMarket}`: a prediction market type 
- `model`: an abm object for the prediction market simulation 
"""
function agent_step!(agent::MarketAgent, ::Type{<:AbstractPredictionMarket}, model)
    for bidx ∈ 1:length(model.order_books)
        remove_orders!(agent, model, bidx)
        order = create_order(agent, model, bidx)
        if order.type == :empty
            push!(model.trade_made[bidx], false)
            market_prices = model.market_prices[bidx]
            isempty(market_prices) ? push!(market_prices, NaN) :
            push!(market_prices, market_prices[end])
        else
            push!(model.trade_made[bidx], transact!(order, model, bidx))
        end
        push!(model.iteration_ids[bidx], abmtime(model))
    end
    return nothing
end

"""
     remove_orders!(agent::MarketAgent, model, bidx)

Removes orders from the specified order book and transfers funds from the bid reserve to
the agent's money fund.     

# Arguments

- `agent::MarketAgent`: an agent participating in the prediction market
- `model`: an abm object for the prediction market simulation 
- `bidx`: the index of the current order book
"""
function remove_orders!(agent::MarketAgent, model, bidx)
    order_book = model.order_books[bidx]
    removed_orders = filter(x -> x.id == agent.id, order_book)
    filter!(x -> x.id ≠ agent.id, order_book)
    for order ∈ removed_orders
        if order.type == :bid
            agent.bid_reserve -= order.price
            agent.money += order.price
        end
    end
    return nothing
end

can_bid(agent::MarketAgent) = agent.money > 0
can_ask(agent::MarketAgent, bidx) = !isempty(agent.shares[bidx])
