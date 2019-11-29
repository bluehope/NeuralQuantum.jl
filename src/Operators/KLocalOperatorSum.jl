"""
    KLocalOperatorSum

A KLocalOperator representing the sum of several KLocalOperator-s. Internally,
the sum is stored as a vector of local operators acting on some sites.
"""
struct KLocalOperatorSum{VS<:AbstractVector,VOp} <: AbsLinearOperator
    # list of sites in this sum
    sites::VS

    # List of operators
    operators::VOp
end

KLocalOperatorSum(op::KLocalOperator) = KLocalOperatorSum([sites(op)], [op])
KLocalOperatorSum(op::AbsLinearOperator) = KLocalOperatorSum([sites(op)], [op])

## Accessors
operators(op::KLocalOperatorSum) = op.operators
conn_type(op::KLocalOperatorSum) = conn_type(eltype(operators(op)))


# Copy
function duplicate(op::KLocalOperatorSum)
    new_sites = deepcopy(op.sites)
    ops = eltype(op.operators)[];
    for _op=operators(op)
        push!(ops, duplicate(_op))
    end

    KLocalOperatorSum(new_sites, ops)
end

#
function row_valdiff!(conn::OpConnection, op::KLocalOperatorSum, v::State)
    for _op=operators(op)
        row_valdiff!(conn, _op, v)
    end
    conn
end

function row_valdiff_index!(conn::OpConnectionIndex, op::KLocalOperatorSum, v::State)
    for _op=operators(op)
        row_valdiff_index!(conn, _op, v)
    end
    conn
end

function map_connections(fun::Function, ∑Ô::KLocalOperatorSum, v::State)
    for Ô=operators(∑Ô)
        map_connections(fun, Ô, v)
    end
    return nothing
end

function accumulate_connections!(acc::AbstractAccumulator, ∑Ô::KLocalOperatorSum, v::State)
    for Ô=operators(∑Ô)
        accumulate_connections!(acc, Ô, v)
    end
    return acc
end

function Base.sum!(op_sum::KLocalOperatorSum, op::AbsLinearOperator)
    id = findfirst(isequal(sites(op)), op_sum.sites)

    if isnothing(id)
        push!(op_sum.sites, sites(op))
        push!(op_sum.operators, op)
    else
        _sum_samesite!(op_sum.operators[id], op)
    end

    return op_sum
end

function Base.sum!(op_l::KLocalOperatorSum, op_r::KLocalOperatorSum)
    for op=operators(op_r)
        sum!(op_l, op)
    end
    op_l
end

+(op_l::KLocalOperatorSum, op::AbsLinearOperator) = sum!(duplicate(op_l), op)
+(op::AbsLinearOperator, ops::KLocalOperatorSum) = ops + op
+(op_l::KLocalOperatorSum, op_r::KLocalOperatorSum) = sum!(duplicate(op_l), op_r)
+(op_l::KLocalOperator, op_r::KLocalOperator) = begin
    sites(op_l) == sites(op_r) && return _sum_samesite(op_l, op_r)
    return KLocalOperatorSum(op_l) + op_r
end

function Base.transpose(ops::KLocalOperatorSum)
    new_sites  = similar(ops.sites)
    new_sites .= ops.sites

    new_ops    = eltype(operators(ops))[]
    for op = operators(ops)
        push!(new_ops, transpose(op))
    end
    return KLocalOperatorSum(new_sites, new_ops)
end

function Base.conj(ops::KLocalOperatorSum)
    new_sites  = similar(ops.sites)
    new_sites .= ops.sites

    new_ops    = eltype(operators(ops))[]
    for op = operators(ops)
        push!(new_ops, conj(op))
    end
    return KLocalOperatorSum(new_sites, new_ops)
end

function Base.conj!(ops::KLocalOperatorSum)
    for op = operators(ops)
        conj!(op)
    end
    return ops
end

Base.adjoint(ops::KLocalOperatorSum) = conj!(transpose(ops))

function *(opl::KLocalOperatorSum, opr::KLocalOperator)
    ∑op =  duplicate(opl)
    for (i,op)=enumerate(operators(∑op))
        op_new = op*opr
        ∑op.operators[i] = op_new
        ∑op.sites[i] = sites(op_new)
    end
    return ∑op
end

function *(opl::KLocalOperator, opr::KLocalOperatorSum)
    ∑op =  duplicate(opr)
    for (i,op)=enumerate(operators(∑op))
        op_new = opl*op
        ∑op.operators[i] = op_new
        ∑op.sites[i] = sites(op_new)
    end
    return ∑op
end

Base.show(io::IO, ::MIME"text/plain", op::KLocalOperatorSum) = print(io,
    "KLocalOperatorSum: \n\t -sites: $(op.sites)")

Base.eltype(::T) where {T<:KLocalOperatorSum} = eltype(T)
Base.eltype(T::Type{KLocalOperatorSum{Vec,VOp}}) where {Vec,VOp} =
    eltype(eltype(VOp))

*(a::Number, b::KLocalOperatorSum) =
    _op_alpha_prod(b,a)
*(b::KLocalOperatorSum, a::Number) =
    _op_alpha_prod(b,a)

function _op_alpha_prod(ops::KLocalOperatorSum, a::Number)
    op_all = [a*op for op=operators(ops)]
    return sum(op_all)
end