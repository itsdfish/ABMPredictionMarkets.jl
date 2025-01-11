using ABMPredictionMarkets: init
"""
    TestAgent(NoSpaceAgent)

An agent that sells and buys shares in a prediction market. 

# Fields

- `judgments::Vector{Int}`: the agent's judgment for probability event e will occur [0, 100]
- `δ::Int`: range of bid and ask noise 
- `money::Int`: the agent's current money available in cents
- `bid_reserve`: bid amount is accounted here to ensure sufficient funds
- `shares::Vector{Order}`: the shares owned by the agent 
"""
@agent struct TestAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Int}
    δ::Int
    money::Int
    bid_reserve::Int
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
    info_times = Int[],
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
            shares = init(Order, n_markets)
        )
    end
    return model
end

function model_step!(model) end

"""
    TestAgent(NoSpaceAgent)

An agent that sells and buys shares in a prediction market. 

# Fields

- `judgments::Vector{Int}`: the agent's judgment for probability event e will occur [0, 100]
- `δ::Int`: range of bid and ask noise 
- `money::Int`: the agent's current money available in cents
- `shares::Vector{Vector{Int}}`: the shares owned by the agent 
"""
@agent struct LSRAgent(NoSpaceAgent) <: MarketAgent
    judgments::Vector{Vector{Float64}}
    money::Float64
    shares::Vector{Vector{Float64}}
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
    ::Type{<:LSRAgent};
    n_agents,
    μ,
    η,
    money,
    info_times = Int[]
)
    space = nothing
    total_money = money * n_agents
    n_options = [4, 2]
    elasticity = set_elasticity.(total_money, n_options, 0.99)
    LSR(; elasticity, n_options, info_times)
    model = StandardABM(
        LSRAgent,
        space;
        properties = LSR(; elasticity, n_options, info_times),
        agent_step!,
        scheduler = Schedulers.Randomly()
    )
    for _ ∈ 1:n_agents
        judgments = rand(Dirichlet(μ .* η))
        marginals = [judgments[1] + judgments[2], judgments[3] + judgments[4]]
        judgments = [judgments, marginals]
        add_agent!(
            model;
            judgments,
            money,
            shares = zeros.(n_options)
        )
    end
    return model
end
