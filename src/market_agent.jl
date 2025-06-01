get_market_type(model) = typeof(abmproperties(model))
get_market(model) = abmproperties(model)
variant(agent::MarketAgent) = agent
variantof(agent::MarketAgent) = typeof(agent)

function create_order(agent::MarketAgent, model, bidx)
    return create_order(agent, variant(agent), get_market(model), model, bidx)
end

function bid(agent::MarketAgent, model, bidx)
    return bid(agent, variant(agent), get_market(model), model, bidx)
end

function ask(agent::MarketAgent, model, bidx)
    return ask(agent, variant(agent), get_market(model), model, bidx)
end

function agent_step!(agent::MarketAgent, model)
    return agent_step!(agent, variant(agent), get_market(model), model)
end

"""
    agent_step!(agent, ::MarketAgent, ::AbstractPredictionMarket, model)

The agent submits a new order for a bid or ask in each market. 
The order is checked against potential sellers (buyers), and 
an exchange is made if one is found. Otherwise, the order is added to the order book.    

# Arguments

- `agent`: an agent participating in the prediction market
- `::MarketAgent`: variant of agent possibly of the same type as `agent`
- `::AbstractPredictionMarket`: a prediction market type 
- `model`: an abm object for the prediction market simulation 
"""
function agent_step!(agent, ::MarketAgent, ::AbstractPredictionMarket, model)
    for bidx ∈ 1:length(model.order_books)
        remove_orders!(agent, model, bidx)
        order = create_order(agent, model, bidx)
        if order.type == :empty
            push!(model.trade_volume[bidx], 0)
            push!(model.iteration_ids[bidx], abmtime(model))
            market_prices = model.market_prices[bidx]
            isempty(market_prices) ? push!(market_prices, NaN) :
            push!(market_prices, market_prices[end])
        else
            transact!(order, model, bidx)
        end
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
            price = order.price * order.quantity
            agent.bid_reserve -= price
            agent.money += price
        end
    end
    return nothing
end

can_bid(agent::MarketAgent) = agent.money > 0
can_ask(agent::MarketAgent, bidx) = !isempty(agent.shares[bidx])
