fn = "0002.sdf"
v_header, data, grids, units = open(deserialize, "0002.jl")

@testset "SDF header" begin
    h = header(fn)
    saved_props = setdiff(propertynames(h),
        [:sdf_magic, :endianness, :summary_location, :summary_size,
        :first_block_location, :nblocks, :block_header_length,
        :string_length])
    for p in saved_props
        @test getproperty(h, p) == getindex(v_header, string(p))
    end
end
