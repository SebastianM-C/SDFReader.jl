struct VectorField{N,T,G} <: AbstractField{N}
    data::T
    grid::G
end

VectorField(data::T, grid::G) where {T <: AbstractArray{A,N} where {A,N}, G} =
    VectorField{dimensionaltiy(G), T, G}(data, grid)

struct VectorVariable{N,T,G} <: AbstractField{N}
    data::T
    grid::G
end

VectorVariable(data::T, grid::G) where {T <: AbstractArray{A,N} where {A,N}, G} =
    VectorVariable{dimensionaltiy(G), T, G}(data, grid)

function VectorField(x::ScalarField)
    data = map(i->SVector{1}(x.data[i]), eachindex(x.data))

    VectorField(data, x.grid)
end

function VectorField(x::ScalarField{N,T,G}, y::ScalarField{N,T,G}) where {N,T,G}
    @assert x.grid == y.grid "Incompatible grids"
    data = map(i->SVector{2}(x.data[i], y.data[i]), eachindex(x.data))

    VectorField(data, x.grid)
end

function VectorField(x::ScalarField{N,T,G}, y::ScalarField{N,T,G}, z::ScalarField{N,T,G}) where {N,T,G}
    @assert x.grid == y.grid == z.grid "Incompatible grids"
    data = map(i->SVector{3}(x.data[i], y.data[i], z.data[i]), eachindex(x.data))

    VectorField(data, x.grid)
end

function VectorVariable(x::ScalarVariable)
    data = map(i->SVector{1}(x.data[i]), eachindex(x.data))

    VectorVariable(data, x.grid)
end

function VectorVariable(x::ScalarVariable{N,T,G}, y::ScalarVariable{N,T,G}) where {N,T,G}
    @assert x.grid == y.grid "Incompatible grids"
    data = map(i->SVector{2}(x.data[i], y.data[i]), eachindex(x.data))

    VectorVariable(data, x.grid)
end

function VectorVariable(x::ScalarVariable{N,T,G}, y::ScalarVariable{N,T,G}, z::ScalarVariable{N,T,G}) where {N,T,G}
    @assert x.grid == y.grid == z.grid "Incompatible grids"
    data = map(i->SVector{3}(x.data[i], y.data[i], z.data[i]), eachindex(x.data))

    VectorVariable(data, x.grid)
end

# Can we make this work with GG?
# It currently gives: The function body AST defined by this @generated function is not pure.
# This likely means it contains a closure or comprehension.
# @generated function VectorField(X::Vararg{ScalarField{M,T,G}, N}) where {N,M,T,G}
#     # How to generalize the assert?
#     # @assert x.grid == y.grid == z.grid "Incompatible grids"
#     quote
#         data = map(i->begin
#             @ncall $N SVector{$N} j->X[j].data[i]
#         end, eachindex(x.data))

#         VectorField(data, X[1].grid)
#     end
# end
