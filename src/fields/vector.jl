struct VectorField{T,G} <: AbstractField
    data::AbstractArray{T,N}
    grid::AbstractArray{G,N}
end
