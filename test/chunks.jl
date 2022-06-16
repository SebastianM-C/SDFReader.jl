using SDFReader
using Serialization
using Test

fn = joinpath(@__DIR__, "0002.sdf")
ref_fn = joinpath(@__DIR__, "0002.jls")
v_header, data, grids, units = open(deserialize, ref_fn)

blocks = file_summary(fn)
unsupported = Symbol.(["cpu/proton", "cpu/electron", "run_info", "cpu_rank"])

@testset "SDFVariable" begin
    open(fn, "r") do f
        @testset "$key" for (key, block) in pairs(blocks)
            if key ∉ unsupported
                sda = SDFVariable(f, block)
                data = read!(f, block)

                @test sda[1, 1, 1] == data[1, 1, 1]
                @test sda[2, 1, 1] == data[2, 1, 1]
                @test sda[1:10, 1, 1] == data[1:10, 1, 1]
                @test sda[15:20] == data[15:20]
                @test sda[:, 1, 1] == data[:, 1, 1]
                @test sda[:] == vec(data)
            end
        end
    end
end
