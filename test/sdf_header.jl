using SDFReader
using Serialization
using Test

fn = joinpath(@__DIR__, "0002.sdf")
ref_fn = joinpath(@__DIR__, "0002.jls")
v_header, data, grids, units = open(deserialize, ref_fn)

h = header(fn)
saved_props = setdiff(propertynames(h),
    [:sdf_magic, :endianness, :summary_location, :summary_size,
        :first_block_location, :nblocks, :block_header_length,
        :string_length])
@testset "$p" for p in saved_props
    @test getproperty(h, p) == getindex(v_header, string(p))
end
