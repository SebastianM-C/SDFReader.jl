module SDF

using BangBang

export header, Header,
    file_summary,
    Stagger, CellCentre, FaceX, FaceY, FaceZ, EdgeX, EdgeY, EdgeZ, Vertex,
    AbstractBlockHeader,
    PlainVariableBlockHeader,
    PointVariableBlockHeader,
    PlainMeshBlockHeader,
    PointMeshBlockHeader

const ID_LENGTH = 32
const ENDIANNESS = 16911887
const SDF_VERSION = 1
const SDF_REVISION = 4
const SDF_MAGIC = "SDF1"

const BLOCKTYPE_SCRUBBED = Int32(-1)
const BLOCKTYPE_NULL = Int32(0)
const BLOCKTYPE_PLAIN_MESH = Int32(1)
const BLOCKTYPE_POINT_MESH = Int32(2)
const BLOCKTYPE_PLAIN_VARIABLE = Int32(3)
const BLOCKTYPE_POINT_VARIABLE = Int32(4)
const BLOCKTYPE_CONSTANT = Int32(5)
const BLOCKTYPE_ARRAY = Int32(6)
const BLOCKTYPE_RUN_INFO = Int32(7)
const BLOCKTYPE_SOURCE = Int32(8)
const BLOCKTYPE_STITCHED_TENSOR = Int32(9)
const BLOCKTYPE_STITCHED_MATERIAL = Int32(10)
const BLOCKTYPE_STITCHED_MATVAR = Int32(11)
const BLOCKTYPE_STITCHED_SPECIES = Int32(12)
const BLOCKTYPE_SPECIES = Int32(13)
const BLOCKTYPE_PLAIN_DERIVED = Int32(14)
const BLOCKTYPE_POINT_DERIVED = Int32(15)
const BLOCKTYPE_CONTIGUOUS_TENSOR = Int32(16)
const BLOCKTYPE_CONTIGUOUS_MATERIAL = Int32(17)
const BLOCKTYPE_CONTIGUOUS_MATVAR = Int32(18)
const BLOCKTYPE_CONTIGUOUS_SPECIES = Int32(19)
const BLOCKTYPE_CPU_SPLIT = Int32(20)
const BLOCKTYPE_STITCHED_OBSTACLE_GROUP = Int32(21)
const BLOCKTYPE_UNSTRUCTURED_MESH = Int32(22)
const BLOCKTYPE_STITCHED = Int32(23)
const BLOCKTYPE_CONTIGUOUS = Int32(24)
const BLOCKTYPE_LAGRANGIAN_MESH = Int32(25)
const BLOCKTYPE_STATION = Int32(26)
const BLOCKTYPE_STATION_DERIVED = Int32(27)
const BLOCKTYPE_DATABLOCK = Int32(28)
const BLOCKTYPE_NAMEVALUE = Int32(29)

const DATATYPE_NULL = Int32(0)
const DATATYPE_INTEGER4 = Int32(1)
const DATATYPE_INTEGER8 = Int32(2)
const DATATYPE_REAL4 = Int32(3)
const DATATYPE_REAL8 = Int32(4)
const DATATYPE_REAL16 = Int32(5)
const DATATYPE_CHARACTER = Int32(6)
const DATATYPE_LOGICAL = Int32(7)
const DATATYPE_OTHER = Int32(8)

include("sdf_header.jl")
include("read_header.jl")
include("read_data.jl")

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
    blocks = NamedTuple()

    block_start = h.summary_location
    for i in Base.OneTo(h.nblocks)
        block = BlockHeader(f, block_start, h.string_length, h.block_header_length)
        blocks = push!!(blocks, Symbol(block.id) => read(f, block))
        block_start = block.next_block_location
    end

    h, blocks
end

end  # module SDF
