struct ScalarField{N,T,D<:AbstractArray{T,N},G} <: AbstractField{T,N}
    data::D
    grid::G
end

struct ScalarVariable{N,T,D<:AbstractArray{T,N},G} <: AbstractField{T,N}
    data::D
    grid::G
end
