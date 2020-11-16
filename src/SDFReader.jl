module SDFReader

export SDF, file_summary, readkeys, get_time
using Unitful
using LinearAlgebra

# using RecursiveArrayTools
# needs broadcast for VectorOfArray

abstract type AbstractField end

include("sdf.jl")
using .SDF

include("traits.jl")
include("units.jl")
include("utils.jl")
# include("fields.jl")
# include("particles.jl")

function Base.read(f, block::AbstractBlockHeader{T, D}) where {T, D}
    raw_data = read!(f, block)

    data = raw_data .* get_normalization(block) .* get_units(block.units)
end

readkeys(file, blocks, keys) = open(file) do f
    asyncmap(k->read(f, blocks[k]), keys)
end

readkeys(file, keys) = readkeys(file, file_summary(file), keys)

end # module
