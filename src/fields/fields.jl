module SimpleFields

export ScalarField, ScalarVariable, VectorField, VectorVariable,
    subsample, slice

using LinearAlgebra
using CoordinateTransformations
using ImageTransformations
using StaticArrays
using RecursiveArrayTools
using ArrayInterface: parameterless_type
using Unitful
using Unitful: Units
using AbstractPlotting

abstract type AbstractField{T,N} <: AbstractArray{T,N} end

include("scalar.jl")
include("vector.jl")
include("units.jl")
include("algebra.jl")
include("transformations.jl")
include("subset.jl")

# Indexing
Base.@propagate_inbounds Base.getindex(f::AbstractField, i::Int) = f.data[i]
Base.@propagate_inbounds Base.setindex!(f::AbstractField, v, i::Int) = f.data[i] = v

Base.firstindex(f::AbstractField) = firstindex(f.data)
Base.lastindex(f::AbstractField) = lastindex(f.data)

Base.size(f::AbstractField, dim...) = size(f.data, dim...)

Base.LinearIndices(f::AbstractField) = LinearIndices(f.data)
Base.IndexStyle(::Type{<:AbstractField}) = Base.IndexLinear()

# Iteration
Base.iterate(f::AbstractField, state...) = iterate(f.data, state...)
Base.length(f::AbstractField) = length(f.data)

# Broadcasting
Base.BroadcastStyle(::Type{<:AbstractField}) = Broadcast.ArrayStyle{AbstractField}()

function Base.similar(f::AbstractField, ::Type{S}, dims::Dims) where S
    parameterless_type(f)(similar(f.data, S, dims), f.grid)
end

function Base.copyto!(dest::AbstractField, src::AbstractField)
    copyto!(dest.data, src.data)

    return dest
end

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{AbstractField}}, ::Type{ElType}) where ElType
    # Scan the inputs for the AbstractField:
    f = find_field(bc)
    grid = f.grid
    # Keep the same grid for the output
    parameterless_type(f)(similar(f.data, ElType, axes(bc)), grid)
end

"""
`A = find_filed(Fs)` returns the first `AbstractField` among the arguments.
"""
find_field(bc::Base.Broadcast.Broadcasted) = find_field(bc.args)
find_field(args::Tuple) = find_field(find_field(first(args)), Base.tail(args))
find_field(f) = f
find_field(::Tuple{}) = nothing
find_field(f::AbstractField, rest) = f
find_field(::Any, rest) = find_field(rest)

# Custom pretty-printing

Base.show(io::IO, ::MIME"text/plain", ::ScalarQuantity) = print(io, "Scalar")
Base.show(io::IO, ::MIME"text/plain", ::VectorQuantity) = print(io, "Vector")

function Base.show(io::IO, m::MIME"text/plain", f::AbstractField)
    show(io, m, scalarness(f))
    data_units = unit(recursive_bottom_eltype(f.data))
    grid_units = unit(recursive_bottom_eltype(f.grid))
    print(io, " with data in " * string(data_units) * ": \n")
    ctx = IOContext(io, :limit=>true, :compact=>true, :displaysize => (10,50))
    Base.print_array(ctx, f.data)
    print(io, "\nand grid in " * string(grid_units) * ": ")
    print(io, f.grid)
end

end # module SimpleFields
