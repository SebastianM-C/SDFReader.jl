using SDFReader
using Serialization
using DiskArrays: haschunks, Chunked
using Test

fn = joinpath(@__DIR__, "0002.sdf")
ref_fn = joinpath(@__DIR__, "0002.jls")
v_header, data, grids, units = open(deserialize, ref_fn)

blocks = file_summary(fn)
unsupported = Symbol.(["cpu/proton", "cpu/electron", "run_info", "cpu_rank", "elapsed_time"])

meshes = Symbol.(["grid", "grid/electron", "grid/proton"])
variables = setdiff(keys(blocks), unsupported, meshes)

@testset "SDFVariable" begin
    open(fn, "r") do f
        @testset "$key" for key in variables
            block = blocks[key]
            sda = SDFVariable(f, block)
            data = read!(f, block)

            @test haschunks(sda) isa Chunked

            @test sda[1, 1, 1] == data[1, 1, 1]
            @test sda[2, 1, 1] == data[2, 1, 1]
            @test sda[1:10, 1, 1] == data[1:10, 1, 1]
            @test sda[15:20] == data[15:20]
            @test sda[:, 1, 1] == data[:, 1, 1]
            @test sda[:] == vec(data)
        end
    end
end

@testset "SDFMesh" begin
    open(fn, "r") do f
        @testset "$key" for key in meshes
            block = blocks[key]
            @testset "$key with axis $axis" for axis in 1:3
                sda = SDFMesh(f, block, axis)
                data = read!(f, block)[axis]

                @test haschunks(sda) isa Chunked

                @test sda[1] == data[1]
                @test sda[2:3] == data[2:3]
                @test sda[1:5] == data[1:5]
                @test sda[5:end] == data[5:end]
                @test sda[begin:end] == data[begin:end]
                @test sda[:] == data[:]
            end
        end
    end
end
