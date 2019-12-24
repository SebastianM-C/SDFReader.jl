
const ID_LENGTH     = 32
const ENDIANNESS    = 16911887
const SDF_VERSION   = 1
const SDF_REVISION  = 4
const SDF_MAGIC     = "SDF1"

const BLOCKTYPE_SCRUBBED                = Int32(-1)
const BLOCKTYPE_NULL                    =  Int32(0)
const BLOCKTYPE_PLAIN_MESH              =  Int32(1)
const BLOCKTYPE_POINT_MESH              =  Int32(2)
const BLOCKTYPE_PLAIN_VARIABLE          =  Int32(3)
const BLOCKTYPE_POINT_VARIABLE          =  Int32(4)
const BLOCKTYPE_CONSTANT                =  Int32(5)
const BLOCKTYPE_ARRAY                   =  Int32(6)
const BLOCKTYPE_RUN_INFO                =  Int32(7)
const BLOCKTYPE_SOURCE                  =  Int32(8)
const BLOCKTYPE_STITCHED_TENSOR         =  Int32(9)
const BLOCKTYPE_STITCHED_MATERIAL       = Int32(10)
const BLOCKTYPE_STITCHED_MATVAR         = Int32(11)
const BLOCKTYPE_STITCHED_SPECIES        = Int32(12)
const BLOCKTYPE_SPECIES                 = Int32(13)
const BLOCKTYPE_PLAIN_DERIVED           = Int32(14)
const BLOCKTYPE_POINT_DERIVED           = Int32(15)
const BLOCKTYPE_CONTIGUOUS_TENSOR       = Int32(16)
const BLOCKTYPE_CONTIGUOUS_MATERIAL     = Int32(17)
const BLOCKTYPE_CONTIGUOUS_MATVAR       = Int32(18)
const BLOCKTYPE_CONTIGUOUS_SPECIES      = Int32(19)
const BLOCKTYPE_CPU_SPLIT               = Int32(20)
const BLOCKTYPE_STITCHED_OBSTACLE_GROUP = Int32(21)
const BLOCKTYPE_UNSTRUCTURED_MESH       = Int32(22)
const BLOCKTYPE_STITCHED                = Int32(23)
const BLOCKTYPE_CONTIGUOUS              = Int32(24)
const BLOCKTYPE_LAGRANGIAN_MESH         = Int32(25)
const BLOCKTYPE_STATION                 = Int32(26)
const BLOCKTYPE_STATION_DERIVED         = Int32(27)
const BLOCKTYPE_DATABLOCK               = Int32(28)
const BLOCKTYPE_NAMEVALUE               = Int32(29)

const DATATYPE_NULL      = 0
const DATATYPE_INTEGER4  = 1
const DATATYPE_INTEGER8  = 2
const DATATYPE_REAL4     = 3
const DATATYPE_REAL8     = 4
const DATATYPE_REAL16    = 5
const DATATYPE_CHARACTER = 6
const DATATYPE_LOGICAL   = 7
const DATATYPE_OTHER     = 8


struct Header
  sdf_magic::String
  endianness::Int32
  version::Int32
  revision::Int32
  code_name::String
  first_block_location::Int64
  summary_location::Int64
  summary_size::Int32
  nblocks::Int32
  block_header_length::Int32
  sym_step::Int32 
  sym_time::Float64
  jobid1::Int32
  jobid2::Int32
  string_length::Int32
  code_io_version::Int32
end

struct BlockHeader
  next_block_location::Int64
  data_location::Int64
  id::String
  data_length::Int64
  block_type::Int32
  d_type::DataType
  n_dims::Int32
  name::String
end

abstract type AbstractBlockHeader end

struct ConstantBlockHeader <: AbstractBlockHeader
  base_header::BlockHeader
end

struct CPUSplitBlockHeader <: AbstractBlockHeader
  base_header::BlockHeader
end

struct PlainVariableBlockHeader{N} <: AbstractBlockHeader
  base_header::BlockHeader

  mult::Float64
  units::String
  mesh_id::String
  npts::Array{Int32, N}
  stagger::Int32
end

struct PointVariableBlockHeader <: AbstractBlockHeader
  base_header::BlockHeader

  mult::Float64
  units::String
  mesh_id::String
  npart::Int64
end

struct PlainMeshBlockHeader{N} <: AbstractBlockHeader
  base_header::BlockHeader
  
  mults::Array{Float64, N}
  labels::Array{String, N}
  units::Array{String, N}
  geometry::Int32
  minval::Array{Float64, N}
  maxval::Array{Float64, N}
  npts::Array{Int32, N}
end

struct PointMeshBlockHeader{N} <: AbstractBlockHeader
  base_header::BlockHeader

  mults::Array{Float64, N}
  labels::Array{String, N}
  units::Array{String, N}
  geometry::Int32
  minval::Array{Float64, N}
  maxval::Array{Float64, N}
  npart::Int64
end

struct CPUInfoBlockHeader <: AbstractBlockHeader
  base_header::BlockHeader
end

function header!(f)
  sdf_magic             = String(read(f, 4))
  endianness            = read(f, Int32)
  version               = read(f, Int32)
  revision              = read(f, Int32)
  code_name             = (String(read(f, ID_LENGTH)))
  first_block_location  = read(f, Int64)
  summary_location      = read(f, Int64)
  summary_size          = read(f, Int32)
  nblocks               = read(f, Int32)
  block_header_length   = read(f, Int32)
  sym_step              = read(f, Int32)
  sym_time              = read(f, Float64)
  jobid1                = read(f, Int32)
  jobid2                = read(f, Int32)
  string_length         = read(f, Int32)
  code_io_version       = read(f, Int32)

  Header(
    sdf_magic, endianness, version, revision, code_name, first_block_location,
    summary_location, summary_size, nblocks, block_header_length, sym_step,
    sym_time, jobid1, jobid2, string_length, code_io_version
  )
end

function type_from(data_type)
  if data_type == DATATYPE_REAL4
    Float32
  elseif data_type == DATATYPE_REAL8
    Float64
  elseif data_type == DATATYPE_INTEGER4
    Int32
  elseif data_type == DATATYPE_INTEGER8
    Int64
  else
    Nothing
  end
end

function read_header!(f, block, ::Val{BLOCKTYPE_CONSTANT})
  ConstantBlockHeader(block)
end

function read_data!(f, block, ::Val{BLOCKTYPE_CONSTANT})
  read(f, block.d_type)
end

function read_variable_common!(f)
  mult    = read(f, Float64)
  units   = String(read(f, ID_LENGTH))
  mesh_id = String(read(f, ID_LENGTH))

  (mult, units, mesh_id)
end

function read_header!(f, block, ::Val{BLOCKTYPE_PLAIN_VARIABLE})
  mult, units, mesh_id = read_variable_common!(f)

  npts = reinterpret(Int32, read(f, block.n_dims*sizeof(Int32)))
  stagger = read(f, Int32)

  PlainVariableBlockHeader(block, mult, units, mesh_id, Array(npts), stagger)
end

function read_data!(f, block, ::Val{BLOCKTYPE_PLAIN_VARIABLE})
  dims = prod(block.npts)
  seek(f, block.data_location)

  reinterpret(block.d_type, read(f, dims*sizeof(block.d_type)))
end

function read_header!(f, block, ::Val{BLOCKTYPE_POINT_VARIABLE})
  mult, units, mesh_id = read_variable_common!(f)
  npart   = read(f, Int64)

  PointVariableBlockHeader(block, mult, units, mesh_id, npart)
end

function read_data!(f, block, ::Val{BLOCKTYPE_POINT_VARIABLE})
  seek(f, block.data_location)

  reinterpret(block.d_type, read(f, block.npart*sizeof(block.d_type)))
end

function read_mesh_common!(f, n)
  labels  = Array{String}(undef, n)
  units   = Array{String}(undef, n)
  
  mults = reinterpret(Float64, read(f, n*sizeof(Float64)))

  for i = 1:n
    labels[i] = String(read(f, ID_LENGTH))
  end
  for i = 1:n
    units[i] = String(read(f, ID_LENGTH))
  end
  geometry = read(f, Int32)
  minval = reinterpret(Float64, read(f, n*sizeof(Float64)))
  maxval = reinterpret(Float64, read(f, n*sizeof(Float64)))

  (mults, labels, units, geometry, minval, maxval)
end

function read_header!(f, block, ::Val{BLOCKTYPE_PLAIN_MESH})
  mults, labels, units, geometry, minval, maxval = read_mesh_common!(f, block.n_dims)
  npts = reinterpret(Int32, read(f, block.n_dims*sizeof(Int32)))

  PlainMeshBlockHeader(
    block, Array(mults), labels, units, geometry,
    Array(minval), Array(maxval), Array(npts)
  )
end

function read_plain_mesh!(f, d_type, data_location, data_length, n)
  n_elems = sum(npts)  # prod?
  type_size = div(data_length, n_elems)
  offset = data_location
  for i = 1:n
    #seek(f, offset)
    #read(f, npts[i] n_elems)
    # print(offset, " ")
    offset = offset + type_size*npts[i]
  end

  (data_location, d_type, n_elems)
end

function read_header!(f, block, ::Val{BLOCKTYPE_POINT_MESH})
  mults, labels, units, geometry, minval, maxval = read_mesh_common!(f, block.n_dims)
  npart = read(f, Int64)

  PointMeshBlockHeader(
    block, Array(mults), labels, units, geometry,
    Array(minval), Array(maxval), npart
  )
end

function read_point_mesh!(f, d_type, data_location, data_length, n)
  mults, labels, units, geometry, minval, maxval = read_mesh_common!(f, n)

  npart = read(f, Int64)

  n_elems = n*npart # ??
  type_size = div(data_length, n_elems)
  offset = data_location
  for i = 1:n
    #seek(f, offset)
    #read(f, npts[i] n_elems)
    # print(offset, " ")
    offset = offset + type_size*npart
  end

  (data_location, d_type, n_elems)
end

function read_header!(f, block, ::Val{BLOCKTYPE_RUN_INFO})
  code_version    = read(f, Int32)
  code_revision   = read(f, Int32)
  commit_id       = String(read(f, ID_LENGTH))
  sha1sum         = String(read(f, ID_LENGTH))
  compile_machine = String(read(f, ID_LENGTH))
  compile_flags   = String(read(f, ID_LENGTH))
  defines         = read(f, Int64)
  compile_date    = read(f, Int32)
  run_date        = read(f, Int32)
  io_date         = read(f, Int32)

  CPUInfoBlockHeader(block)
end

function read_header!(f, block, ::Val{BLOCKTYPE_CPU_SPLIT})
  CPUSplitBlockHeader(block)
end

function fetch_blocks(filename)
  open(filename, "r") do f
    r = header!(f)
    blocks = Array{AbstractBlockHeader}(undef, r.nblocks)

    block_start = r.first_block_location
    for i = 1:r.nblocks
      seek(f, block_start)
      next_block_location = read(f, Int64)
      data_location       = read(f, Int64)
      id                  = String(read(f, ID_LENGTH))
      data_length         = read(f, Int64)
      block_type          = read(f, Int32)
      data_type           = read(f, Int32)
      n_dims              = read(f, Int32)
      name                = String(read(f, r.string_length))

      seek(f, block_start + r.block_header_length)
      d_type = type_from(data_type)

      block = BlockHeader(
        next_block_location, data_location, id, data_length,
        block_type, d_type, n_dims, name
      )
      blocks[i] = read_header!(f, block, Val(block_type))
      block_start = next_block_location
    end

    blocks
  end
end

function main()
  fetch_blocks(ARGS[1])
end
