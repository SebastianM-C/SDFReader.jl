using SDFReader
using Test
using Serialization
using Compat

@testset "SDFReader.jl" begin
    include("sdf.jl")
    include("api.jl")
end