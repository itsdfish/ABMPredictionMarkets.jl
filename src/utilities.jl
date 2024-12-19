"""
    compute_unpacking_factor(model)

Computes the ratio of sum of subevents probabilities to the event probability for a 2×2 partition. 
Event e is indexed by 1 and subevents e₁ and e₂ are indexed by 2 and 3. Probability theory requires
p(e) = p(e₁) + p(e₂).

Arguments 

- `model`: an abm object for the prediction market simulation 
"""
function compute_unpacking_factor(model)
    return (model.market_prices[1] .+ model.market_prices[2]) ./ model.market_prices[5]
end

"""
    compute_returns(shares, p_true)

Computes the expected return of a vector of shares. 

# Arguments

- `shares`: a vector of shares 
- `p_true`: the true probability of the event 
"""
function compute_returns(shares, p_true)
    v = 0.0
    for s ∈ shares
        v += s.yes ? s.price - p_true : (100 - s.price) - p_true
    end
    return v
end

"""
    compute_trade_volume(trade_made, interval_length)

Computes trade volume for a set of time intervals 

# Arguments

- `trade_made`: indicates whether a trade is made on each agent step 
- `interval_length`: the length of the interval in which trade volume is computed
"""
function compute_trade_volume(trade_made, interval_length)
    n = div(length(trade_made), interval_length)
    return map(
        i -> sum(trade_made[((i - 1) * interval_length + 1):(i * interval_length)]),
        1:n
    )
end

"""
    DiscreteDirichlet{T} <: ContinuousMultivariateDistribution

A discrete version of Dirchlet distribution which sums to 100. 

# Fields

- `μ::Vector{T}`: mean probabilities which sum to 1
- `η::T`: a scalar multiple of `μ` inversely related to variance. 
"""
struct DiscreteDirichlet{T} <: ContinuousMultivariateDistribution
    μ::Vector{T}
    η::T
end

function rand(dist::DiscreteDirichlet)
    x = Int.(round.(rand(Dirichlet(dist.μ .* dist.η)) * 100))
    x[4] = 100 - sum(x[1:3])
    return x
end
