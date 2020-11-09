@testset "SDF" begin
    include("sdf_header.jl")
    fn = "0002.sdf"
    blocks = SDF.file_summary(fn)

    @testset "Units" begin
        for (key, block) in blocks
            if @compat hasfield(typeof(block), :units)
                @test block.units == units[key]
            end
        end
    end

    unsupported = ["cpu/proton", "cpu/electron", "run_info", "cpu_rank"]
    @testset "Data" begin
        open(fn, "r") do f
            @testset "$key" for (key, block) in blocks
                if key ∉ unsupported
                    @test read!(f, block) == data[key]
                end
            end
        end
    end
end
