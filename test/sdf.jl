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
end
