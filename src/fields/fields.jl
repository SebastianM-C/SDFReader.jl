using LinearAlgebra
using CoordinateTransformations
using ImageTransformations
using StaticArrays
using Unitful
using Unitful: Units

abstract type AbstractField{N} end

dimensionaltiy(::AbstractField{N}) where N = N
dimensionaltiy(::Type{NTuple{N, T}}) where {N, T} = N
dimensionaltiy(::Type{T}) where T <: AbstractArray{A, N} where {A,N} = N
dimensionaltiy(::Type{T}) where T <: AbstractVector{SVector{N, A}} where {A,N} = N
dimensionaltiy(::Type{T}) where T <: AbstractVector{Cylindrical{R,A}} where {R,A} = 3
dimensionaltiy(::Type{T}) where T <: AbstractVector{Spherical{R,A}} where {R,A} = 3
dimensionaltiy(::Any) = 0

include("scalar.jl")
include("vector.jl")
include("units.jl")
include("algebra.jl")
include("transformations.jl")
include("subset.jl")

for F in (:ScalarField,:VectorField,:ScalarVariable,:VectorVariable)
    @eval begin
        function field(::$F, data, grid)
            ($F)(data, grid)
        end
    end
end
