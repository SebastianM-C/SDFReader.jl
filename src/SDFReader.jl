module SDFReader

export readdump, ScalarField

using PyCall
using Unitful: Unitful, Units, @u_str

const sdf = PyNULL()
const sh = PyNULL()

function __init__()
    copy!(sdf, pyimport("sdf"))
    copy!(sh, pyimport("sdf_helper"))
end

include("utils.jl")

struct ScalarField{T,N,A,D,U}
    data::Array{T,N}
    grid::NTuple{N,A}
    units::Units{U,D}
end

function ScalarField(data::PyArray{T,N}, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    ScalarField{T,N,A,D,U}(data, grid, units)
end

function ScalarField(dump::PyObject, key::Symbol)
    py_obj = getproperty(dump, key)
    data = convert_it(py_obj.data)
    data_size = size(data)
    unit_str = py_obj.units
    # workaround stuff like 1/m^3
    if !occursin(r"1\/([a-z]*\^[0-9]?)", unit_str)
        units = getfield(Unitful, Symbol(py_obj.units))
    else
        u = replace(unit_str, r"1\/([a-z]*)\^([0-9]?)" => s"\g<1>^-\g<2>")
        units = @eval @u_str $u
    end
    grid = convert_it.(py_obj.grid.data)
    if data_size == length.(grid)
        field = ScalarField(data, grid, units)
    else
        grid_mid = convert_it.(py_obj.grid_mid.data)
        field = ScalarField(data, grid_mid, units)
    end
end

function readdump(path)
    sdf.read(path)
end

end # module
