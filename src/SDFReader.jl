module SDFReader

export header, Header,
    file_summary,
    Stagger, CellCentre, FaceX, FaceY, FaceZ, EdgeX, EdgeY, EdgeZ, Vertex,
    AbstractBlockHeader,
    PlainVariableBlockHeader,
    PointVariableBlockHeader,
    PlainMeshBlockHeader,
    PointMeshBlockHeader

using Unitful

include("constants.jl")
include("sdf_header.jl")
include("read_header.jl")
include("read_data.jl")
include("units.jl")
include("utils.jl")

@generated function typemap(data_type::Val{N}) :: DataType where N
    if N == DATATYPE_NULL
        Nothing
    elseif N == DATATYPE_INTEGER4
        Int32
    elseif N == DATATYPE_INTEGER8
        Int64
    elseif N == DATATYPE_REAL4
        Float32
    elseif N == DATATYPE_REAL8
        Float64
    elseif N == DATATYPE_REAL16
        Nothing # unsupported
    elseif N == DATATYPE_CHARACTER
        Char
    elseif N == DATATYPE_LOGICAL
        Bool
    else
        Nothing
    end
end

file_summary(filename) = open(file_summary, filename)[2]

function file_summary(f::IOStream)
    h = header(f)
    blocks = Dict{Symbol,AbstractBlockHeader}()

    block_start = h.summary_location
    for i in Base.OneTo(h.nblocks)
        block = BlockHeader(f, block_start, h.string_length, h.block_header_length)
        blocks = push!(blocks, Symbol(block.id) => read(f, block))
        block_start = block.next_block_location
    end

    h, blocks
end

function Base.read(f, block::AbstractBlockHeader{T, D}) where {T, D}
    raw_data = read!(f, block)
    data = raw_data .* get_normalization(block) .* get_units(block.units)
end

end # module
