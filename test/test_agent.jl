using ABMPredictionMarkets: init
"""
    TestAgent(NoSpaceAgent)

An agent that sells and buys shares in a prediction market. 

# Fields

- `judgments::Vector{Int}`: the agent's judgment for probability event e will occur [0, 100]
- `δ::Int`: range of bid and ask noise 
- `money::Int`: the agent's current money available in cents
- `shares::Vector{Order}`: the shares owned by the agent 
"""
@agent struct TestAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Int}
    δ::Int
    money::Int
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
        n_markets,
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
- `n_markets`: the number of available markets in the simulation 
"""
function initialize(
    ::Type{<:TestAgent};
    n_agents,
    μ,
    η,
    δ,
    money,
    info_times = Int[],
    n_markets
)
    space = nothing
    model = StandardABM(
        TestAgent,
        space;
        properties = DoubleContinuousAuction(; n_markets, info_times),
        agent_step!,
        scheduler = Schedulers.Randomly()
    )
    for _ ∈ 1:n_agents
        judgments = rand(DiscreteDirichlet(μ, η))
        push!(judgments, judgments[1] + judgments[2])
        add_agent!(
            model;
            judgments,
            money,
            δ,
            shares = init(Order, n_markets)
        )
    end
    return model
end
