struct ScalarField{N,T,G} <: AbstractField{N}
    data::T
    grid::G
end

ScalarField(data::T, grid::G) where {T <: AbstractArray{A,N} where {A,N}, G} =
    ScalarField{dimensionaltiy(G), T, G}(data, grid)

struct ScalarVariable{N,T,G} <: AbstractField{N}
    data::T
    grid::G
end

ScalarVariable(data::T, grid::G) where {T <: AbstractVector, G} =
    ScalarVariable{dimensionaltiy(G), T, G}(data, grid)
