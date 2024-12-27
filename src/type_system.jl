"""
    MarketAgent <: AbstractAgent

An agent that submits bids and asks in a prediction market. 
"""
abstract type MarketAgent <: AbstractAgent end

abstract type AbstractOrder end

abstract type AbstractPredictionMarket end

abstract type AbstractDCA <: AbstractPredictionMarket end

abstract type AbstractLSR <: AbstractPredictionMarket end

