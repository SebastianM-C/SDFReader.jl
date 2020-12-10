struct VectorField{N,T,G} <: AbstractField
    data::AbstractArray{T,N}
    grid::NTuple{N,G}
end
