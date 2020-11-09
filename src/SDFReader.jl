module SDFReader

export SDF, file_summary, readkeys

using Unitful
# using RecursiveArrayTools
# needs broadcast for VectorOfArray

include("sdf.jl")
using .SDF

# include("fields.jl")
# include("particles.jl")

readkeys(file, blocks, keys) = open(file) do f
    asyncmap(k->read(f, blocks[k]), keys)
end

end # module
