module SDFReader

export SDF, file_summary,
    read_simulation, EPOCHSimulation, SDFFile,
    ScalarField, VectorField, ScalarVariable, VectorVariable,
    dimensionaltiy, field,
    get_parameter, get_time,
    to_cylindrical

using Unitful
using PhysicalConstants.CODATA2018: c_0, ε_0, μ_0, m_e, e
using Statistics, StatsBase
using BangBang

include("sdf/sdf.jl")
using .SDF

include("traits.jl")
include("units.jl")
include("utils.jl")
include("fields/fields.jl")
using .SimpleFields

include("fields/read_scalar.jl")
include("input/parser.jl")
include("api/simulation.jl")

function Base.read(f, block::AbstractBlockHeader{T, D}) where {T, D}
    raw_data = read!(f, block)
    data = raw_data .* get_normalization(block) .* get_units(block.units)
end

end # module
