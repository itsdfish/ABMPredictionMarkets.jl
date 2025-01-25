"""
    Order <: AbstractOrder

An object representing a bid, ask, or share. 

# Fields 

- `id::Int`: agent id 
- `yes::Bool`: true if represents a `yes` share 
- `price::Int`: the price of the share, price ∈ [0,100]
- `type::Symbol`: object type type ∈ [bid,ask,share]

# Constructors 

    Order(id, yes, price, type)

    Order(; id, yes, price, type)
"""
mutable struct Order <: AbstractOrder
    id::Int
    yes::Bool
    price::Int
    quantity::Int
    type::Symbol
end

Order(; id, yes, price, quantity, type) = Order(id, yes, price, quantity, type)

function ≠(s1::Order, s2::Order)
    for f ∈ fieldnames(Order)
        getproperty(s1, f) ≠ getproperty(s2, f) ? (return true) : nothing
    end
    return false
end

function ==(s1::Order, s2::Order)
    for f ∈ fieldnames(Order)
        getproperty(s1, f) ≠ getproperty(s2, f) ? (return false) : nothing
    end
    return true
end
