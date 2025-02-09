cd(@__DIR__)
using Pkg
Pkg.activate(".")
using ABMPredictionMarkets
using Agents
using Plots
using Statistics
using Random
using Test
include("model_code.jl")

Random.seed!(845)

n_days = 100
n_agents = 100
μ = [0.20, 0.30, 0.50]
n_markets = length(μ)
model = initialize(
    TestAgent;
    n_agents,
    μ,
    η = 20.0,
    money = 20_000,
    δ = 3,
    max_quantity = 3
)

run!(model, n_days)

market_prices = map(i -> model.market_prices[i][1:n_agents:end], 1:n_markets)
plot(
    market_prices,
    xticks = nothing,
    yticks = nothing,
    ylims = (0, .70),
    grid = false,
    label = false,
    background_color=:transparent,
    color = [RGB(.251, .388, .847) RGB(.584, .345, .698) RGB(.796, .235, .20)],
    size = (600,300)
)

savefig("logo.svg")