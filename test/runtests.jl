using SDFReader
using Test
using Serialization

@testset "SDFReader.jl" begin
    data, grids, units = deserialize("0002.jl")
    include("sdf.jl")
end
