using LRUCache

@testset "SDF" begin
    include("sdf_header.jl")
    fn = "0002.sdf"
    blocks = file_summary(fn)

    @testset "Units" begin
        for (key, block) in pairs(blocks)
            if hasfield(typeof(block), :units)
                @test block.units == units[string(key)]
            end
        end
    end

    unsupported = Symbol.(["cpu/proton", "cpu/electron", "run_info", "cpu_rank"])
    @testset "Data" begin
        open(fn, "r") do f
            @testset "$key" for (key, block) in pairs(blocks)
                if key ∉ unsupported
                    @test read!(f, block) == data[string(key)]
                end
            end
        end
    end

    @testset "Utilities" begin
        @test nameof(blocks[:ex]) == "Electric Field/Ex"
        @test labels(blocks[:grid]) == ("X", "Y", "Z")
        @test labels(blocks[Symbol("grid/electron")]) == ("X", "Y", "Z")
    end

    @testset "Cache" begin
        cache = LRU{Tuple{String,AbstractBlockHeader},AbstractArray}(maxsize=2)
        open(fn, "r") do f
            t1 = 0.
            t2 = 0.
            @testset "store" begin
                ex = @timed cached_read(f, blocks[:ex], cache)
                @test read(f, blocks[:ex]) == ex.value
                t1 = ex.time
                @test read(f, blocks[:ey]) == cached_read(f, blocks[:ey], cache)
            end
            @testset "load" begin
                ex = @timed cached_read(f, blocks[:ex], cache)
                @test read(f, blocks[:ex]) == ex.value
                @test read(f, blocks[:ey]) == cached_read(f, blocks[:ey], cache)
                t2 = ex.time
                # test that the cache was used
                @test t2 < 100t1
                @test length(cache) == 2
            end
        end
    end
end
