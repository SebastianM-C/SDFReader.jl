@testset "SDF" begin
    include("sdf_header.jl")
    blocks = SDF.fetch_blocks(fn)
end
