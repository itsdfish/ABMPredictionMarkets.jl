"""
    Order <: AbstractOrder

An object representing a bid, ask, or share. 

# Fields 

- `id::Int`: agent id 
- `yes::Bool`: true if represents a `yes` share 
- `price::Int`: the price of a single share, price ∈ [0,100]
- `quantity::Int`: the number of shares at a given price 
- `type::Symbol`: object type type ∈ [bid,ask,share]

# Constructors 

    Order(id, yes, price, quantity, type)

    Order(; id, yes, price, quantity, type)
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

"""
    Order <: AbstractOrder

An object representing a bid, ask, or share. 

# Fields 

- `id::Int`: agent id 
- `option_id`: option id
- `cost::Float64`: total cost of order
- `n_shares`: the number of shares in the order

# Constructors 

    LSROrder(id, option, cost, n_shares)

    LSROrder(; id, option, cost, n_shares)
"""
mutable struct LSROrder <: AbstractOrder
    id::Int
    option::Int
    cost::Float64
    n_shares::Float64
end

function LSROrder(; id, option, cost, n_shares)
    return LSROrder(id, option, cost, n_shares)
end
