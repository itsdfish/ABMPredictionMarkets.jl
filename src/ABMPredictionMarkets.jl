module ABMPredictionMarkets
using Agents
using Distributions
using Random

import Base: ==
import Base: ≠
import Distributions: rand
import Distributions: ContinuousUnivariateDistribution

export AbstractOrder
export AbstractPredictionMarket
export DoubleContinuousAuction
export DiscreteDirichlet
export MarketAgent
export Order

export agent_step!
export compute_unpacking_factor
export initialize
export model_step!
export plot_dashboard
export plot_depth_chart
export compute_trade_volume

include("prediction_market_structs.jl")
include("market_agent.jl")
include("prediction_market.jl")
include("utilities.jl")
include("ext_functions.jl")
end
