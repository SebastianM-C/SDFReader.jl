module SDFReader

export readdump, ScalarField, electric_field_magnitude

using PyCall
using Unitful: Unitful, Units, @u_str
using LinearAlgebra

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

function get_units(unit_str)
    # workaround stuff like 1/m^3
    if !occursin(r"1\/([a-z]*\^[0-9]?)", unit_str)
        units = @eval @u_str $unit_str
    else
        u = replace(unit_str, r"1\/([a-z]*)\^([0-9]?)" => s"\g<1>^-\g<2>")
        units = @eval @u_str $u
    end
end

function ScalarField(dump::PyObject, key::Symbol)
    py_obj = getproperty(dump, key)
    data = convert_it(py_obj.data)
    data_size = size(data)
    units = get_units(py_obj.units)
    grid = convert_it.(py_obj.grid.data)
    if data_size == length.(grid)
        field = ScalarField(data, grid, units)
    else
        grid_mid = convert_it.(py_obj.grid_mid.data)
        field = ScalarField(data, grid_mid, units)
    end
end

"""
    readdump(path)

Read the EPOCH dump file (.sdf) at the given path. It does not read the variables
saved in the file, it only returns a PyObject pointing to the file.
This can be used to view the contents of the file and as input
for other functions to actuall read the variables of interest.
"""
function readdump(path)
    sdf.read(path)
end

"""
    electric_field_magnitude(dump)

Compute the magnitude of the electric field stored in the gievn output dump.
"""
function electric_field_magnitude(dump)
    py_ex = dump.Electric_Field_Ex
    py_ey = dump.Electric_Field_Ey
    py_ez = dump.Electric_Field_Ez

    ex = convert_it(py_ex.data)
    ey = convert_it(py_ey.data)
    ez = convert_it(py_ez.data)

    E = Array{eltype(ex),3}(undef, size(ex)...)
    for i in eachindex(ex)
        E[i] = sqrt(ex[i]^2 + ey[i]^2 + ez[i]^2)
    end
    units = get_units(py_ex.units)
    grid_mid = convert_it.(py_ex.grid_mid.data)
    ScalarField(E, grid_mid, units)
end

end # module
