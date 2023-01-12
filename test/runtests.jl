using Test
using SafeTestsets

@testset "SDFReader.jl" begin
    @safetestset "SDF header" begin include("sdf_header.jl") end
    @safetestset "SDF data" begin include("sdf.jl") end
    @safetestset "DiskArrays integration" begin include("chunks.jl") end
    @safetestset "mmap" begin include("mmap.jl") end
end
