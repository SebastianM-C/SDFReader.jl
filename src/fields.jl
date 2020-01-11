using LinearAlgebra

abstract type AbstractQuantity end

struct Field{T,N,A} <: AbstractQuantity
    data::Array{T, N}
    grid::NTuple{N, A}
end

function Field(data, grid, units)
    Field(data*units, grid)
end

function Field(x::AbstractArray{T,N}, y::AbstractArray{T,N}, grid, units) where {T,N}
    data = Vec{2,T}.(x, y)
    Field(data*units, grid)
end

function Field(x::AbstractArray{T,N}, y::AbstractArray{T,N}, z::AbstractArray{T,N}, grid, units) where {T,N}
    data = Vec{3,T}.(x, y, z)
    Field(data*units, grid)
end

function Field(fn::AbstractString, block::AbstractBlockHeader)
    data = read!(fn, block)
    data_size = size(data)
    units = get_units(block.units)
    grid = convert_it.(py_obj.grid.data)
    if data_size == length.(grid)
        Field(data, grid, units)
    else
        grid_mid = convert_it.(py_obj.grid_mid.data)
        Field(data, grid_mid, units)
    end
end

for f in (:+, :-, :*, :/)
    @eval function (Base.$f)(f1::AbstractQuantity, f2::AbstractQuantity)
        Field(($f).(f1.data, f2.data), f1.grid)
    end
end

function LinearAlgebra.cross(f1::AbstractQuantity, f2::AbstractQuantity)
    Field(cross.(f1.data, f2.data), f1.grid)
end

LinearAlgebra.norm(field::AbstractQuantity) = Field(norm.(field.data), field.grid)
