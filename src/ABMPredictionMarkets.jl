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
export AbstractCDA
export CDA
export DiscreteDirichlet
export MarketAgent
export Order

export agent_step!
export compute_unpacking_factor
export initialize
export plot_dashboard
export plot_depth_chart
export compute_trade_volume

include("type_system.jl")
include("orders.jl")
include("continuous_double_auction.jl")
include("logarithmic_scoring_rule.jl")
include("market_agent.jl")
include("utilities.jl")
include("ext_functions.jl")
end
