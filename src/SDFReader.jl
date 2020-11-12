module SDFReader

export SDF, file_summary, readkeys, get_time
using Unitful
# using RecursiveArrayTools
# needs broadcast for VectorOfArray

include("sdf.jl")
include("units.jl")
include("utils.jl")
# include("fields.jl")
# include("particles.jl")

using .SDF

function Base.read(f, block::AbstractBlockHeader{T, D}) where {T, D}
    raw_data = read!(f, block)

    raw_data .* get_units(block.units)
end

readkeys(file, blocks, keys) = open(file) do f
    asyncmap(k->read(f, blocks[k]), keys)
end

end # module
