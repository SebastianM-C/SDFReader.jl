module SDFReader

export filereader, Field, particle_variable, build_vector, electric_field

using PyCall
using Unitful: Unitful, Units, @u_str
using GeometryTypes
using LinearAlgebra
# using RecursiveArrayTools
# needs broadcast for VectorOfArray

const sdf = PyNULL()
const sh = PyNULL()

function __init__()
    copy!(sdf, pyimport("sdf"))
    copy!(sh, pyimport("sdf_helper"))
end

include("utils.jl")

struct Field{T,N,A}
    data::Array{T, N}
    grid::NTuple{N, A}
end

function Field(data, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    Field(data*units, grid)
end

function Field(x, y, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    data = Vec{2,T}.(x, y)
    Field(data*units, grid)
end

function Field(x, y, z, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    data = Vec{3,T}.(x, y, z)
    Field(data*units, grid)
end

function get_units(unit_str)
    # workaround stuff like kg.m/s
    unit_str = replace(unit_str, "."=>"*")
    # workaround stuff like 1/m^3
    if !occursin(r"1\/([a-z]*\^[0-9]?)", unit_str)
        units = @eval @u_str $unit_str
    else
        u = replace(unit_str, r"1\/([a-z]*)\^([0-9]?)" => s"\g<1>^-\g<2>")
        units = @eval @u_str $u
    end
end

function Field(fr::PyObject, key::Symbol)
    py_obj = getproperty(fr, key)
    data = convert_it(py_obj.data)
    data_size = size(data)
    units = get_units(py_obj.units)
    grid = convert_it.(py_obj.grid.data)
    if data_size == length.(grid)
        Field(data, grid, units)
    else
        grid_mid = convert_it.(py_obj.grid_mid.data)
        Field(data, grid_mid, units)
    end
end

function particle_variable(data::PyArray{T,N}, units::Units{U,D}) where {T,N,D,U}
    Array(data*units)
end

function particle_variable(x::PyArray{T,N}, y::PyArray{T,N}, units::Units{U,D}) where {T,N,D,U}
    data = Point{2,T}.(x, y)
    Array(data*units)
end

function particle_variable(x::PyArray{T,N}, y::PyArray{T,N}, z::PyArray{T,N}, units::Units{U,D}) where {T,N,D,U}
    data = Point{3,T}.(x, y, z)
    Array(data*units)
end

function particle_variable(fr::PyObject, key::Symbol)
    py_obj = getproperty(fr, key)
    @debug "Reading data"
    py_data = py_obj.data
    if py_data isa Tuple
        @debug "Converting vector data"
        data = convert_it.(py_data)
        @debug "Reading units"
        units = get_units.(py_obj.units)
        @assert length(unique(units)) == 1
        particle_variable(data..., units[1])
    else
        @debug "Converting scalar data"
        data = convert_it(py_data)
        @debug "Reading units"
        units = get_units(py_obj.units)
        particle_variable(data, units)
    end
end

for f in (:+, :-, :*, :/)
    @eval function (Base.$f)(f1::Field, f2::Field)
        Field(($f).(f1.data, f2.data), f1.grid)
    end
end

function LinearAlgebra.cross(f1::Field, f2::Field)
    Field(cross.(f1.data, f2.data), f1.grid)
end

LinearAlgebra.norm(field::Field) = Field(norm.(field.data), field.grid)

function build_vector(v::Vararg{T,N}) where {N,T}
    Array(Point{N}.(v...))
end

"""
    filereader(path; convert=false)

Return a file reader for the EPOCH dump file (.sdf) at the given path.
The values can be optionally converted to 32 bits with the `convert` argument.
"""
function filereader(path; convert=false)
    sdf.read(path, convert=convert)
end

function electric_field(fr)
    py_ex = fr.Electric_Field_Ex
    py_ey = fr.Electric_Field_Ey
    py_ez = fr.Electric_Field_Ez

    ex = convert_it(py_ex.data)
    ey = convert_it(py_ey.data)
    ez = convert_it(py_ez.data)

    units = get_units(py_ex.units)
    grid_mid = convert_it.(py_ex.grid_mid.data)
    Field(ex, ey, ez, grid_mid, units)
end

end # module
