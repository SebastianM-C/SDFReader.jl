module SDFReader

export filereader, Field, particle_variable, build_vector, electric_field

using PyCall
using Unitful: Unitful, Units, @u_str
using GeometryTypes
# using RecursiveArrayTools
# needs broadcast for VectorOfArray

const sdf = PyNULL()
const sh = PyNULL()

function __init__()
    copy!(sdf, pyimport("sdf"))
    copy!(sh, pyimport("sdf_helper"))
end

include("utils.jl")
include("fields.jl")
include("particles.jl")
include("sdf.jl")

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
