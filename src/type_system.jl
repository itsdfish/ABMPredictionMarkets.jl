"""
    MarketAgent <: AbstractAgent

An agent that submits bids and asks in a prediction market. 
"""
abstract type MarketAgent <: AbstractAgent end

"""
    AbstractOrder

An abstract type representing bids and asks. 
"""
abstract type AbstractOrder end

"""
    AbstractPredictionMarket

An abstract type for a prediction market. 
"""
abstract type AbstractPredictionMarket end

"""
    AbstractCDA <: AbstractPredictionMarket

An abstract type for a continuous double auction prediction market. 
"""
abstract type AbstractCDA <: AbstractPredictionMarket end

"""
    AbstractLSR <: AbstractPredictionMarket

An abstract type for a prediction market using a logarithmic scoring rule. 
"""
abstract type AbstractLSR <: AbstractPredictionMarket end
