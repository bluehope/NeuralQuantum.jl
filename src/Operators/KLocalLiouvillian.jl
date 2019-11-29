struct KLocalLiouvillian{T,A,B,C} <: AbsLinearOperator
    sites::T
    HnH_l::A
    HnH_r::B
    LLdag::C
end

function KLocalLiouvillian(HnH, Lops)
    T = eltype(HnH)
    HnH_l = T(-1.0im) * KLocalOperatorTensor(HnH, nothing)
    HnH_r = T(1.0im) * KLocalOperatorTensor(nothing, HnH')

    LLdag_list = [KLocalOperatorTensor(L, conj(L)) for L=Lops]
    LLdag = isempty(LLdag_list) ? [] : sum(LLdag_list)

    return KLocalLiouvillian([], HnH_l, HnH_r, LLdag)
end

sites(op::KLocalLiouvillian) = op.sites

conn_type(op::KLocalLiouvillian) = conn_type(op.HnH_l)

accumulate_connections!(a, b::Vector, c) = nothing

function accumulate_connections!(acc::AbstractAccumulator, op::KLocalLiouvillian, v::DoubleState)
    accumulate_connections!(acc, op.HnH_l, v)
    accumulate_connections!(acc, op.HnH_r, v)
    accumulate_connections!(acc, op.LLdag, v)

    return acc
end

function map_connections(fun::Function, op::KLocalLiouvillian, v::DoubleState)
    map_connections(fun, op.HnH_l, v)
    map_connections(fun, op.HnH_r, v)
    map_connections(fun, op.LLdag, v)
    return nothing
end

Base.show(io::IO, m::MIME"text/plain", op::KLocalLiouvillian) = begin
    T    = eltype(op.HnH_l)

    print(io, "KLocalLiouvillian($T)")
end