using Unitful

@testset "Public API tests" begin
    dir = pwd()
    file = "0002.sdf"
    blocks = file_summary(file)
    @test getindex(blocks, "ex") isa SDFReader.AbstractBlockHeader

    k = ["grid/electron",
        "py/electron",
        "pz/electron",
        "ex"]
    (x,y,z), py, pz, ex = readkeys(file, blocks, k)
    @test all(unit.(x) .== u"m")
    @test all(unit.(py) .== u"kg*m/s")
    @test all(unit.(ex) .== u"V/m")

    t = get_time(file)
    @test (t |> u"fs") ≈ 10u"fs" atol = 0.1u"fs"
end
