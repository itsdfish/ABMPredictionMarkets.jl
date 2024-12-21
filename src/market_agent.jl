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
        order = create_order(agent, model, bidx)
        push!(model.trade_made[bidx], find_trade!(order, model, bidx))
    end
    return nothing
end

can_bid(agent::MarketAgent) = agent.money > 0
can_ask(agent::MarketAgent, bidx) = !isempty(agent.shares[bidx])
