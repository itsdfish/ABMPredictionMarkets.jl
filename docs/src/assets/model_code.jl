using ABMPredictionMarkets: init
"""
    TestAgent(NoSpaceAgent)

An agent that sells and buys shares in a prediction market. 

# Fields

- `judgments::Vector{Int}`: the agent's judgment for probability event e will occur [0, 100]
- `δ::Int`: range of bid and ask noise 
- `money::Int`: the agent's current money available in cents
- `bid_reserve`: bid amount is accounted here to ensure sufficient funds
- `max_quantity`: maximum quantity traded per iteration
- `shares::Vector{Order}`: the shares owned by the agent 
"""
@agent struct TestAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Int}
    δ::Int
    money::Int
    bid_reserve::Int
    max_quantity::Int
    shares::Vector{Vector{Order}}
end

"""
    initialize(
        ::Type{<:TestAgent};
        n_agents,
        μ,
        η,
        δ,
        money,
        info_times = Int[]
    )

Initializes a model for sub-and-super-additivity in prediction markets. 

# Keywords

- `::Type{<:TestAgent}`: a quantum agent type with compatible beliefs
- `n_agents`: the number of agents
- `μ`: mean belief for yes event
- `σ`: standard deviation of belief for yes event across agents
- `δ::Int`: range of bid and ask noise 
- `money`: the initial amount of money in cents each agent is given
- `info_times`: a vector of days on which new information is provided 
"""
function initialize(
    ::Type{<:TestAgent};
    n_agents,
    μ,
    η,
    δ,
    money,
    max_quantity = 1,
    info_times = Int[]
)
    space = nothing
    n_markets = length(μ)
    model = StandardABM(
        TestAgent,
        space;
        properties = CDA(; n_markets, info_times),
        agent_step!,
        model_step!,
        scheduler = Schedulers.Randomly()
    )
    for _ ∈ 1:n_agents
        add_agent!(
            model;
            judgments = rand(DiscreteDirichlet(μ, η)),
            money,
            bid_reserve = 0,
            δ,
            max_quantity,
            shares = init(Order, n_markets)
        )
    end
    return model
end

function model_step!(model) end
