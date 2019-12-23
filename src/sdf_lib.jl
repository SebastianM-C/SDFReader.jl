
const ID_LENGTH     = 32
const ENDIANNESS    = 16911887
const SDF_VERSION   = 1
const SDF_REVISION  = 4
const SDF_MAGIC     = "SDF1"

const BLOCKTYPE_SCRUBBED                = -1
const BLOCKTYPE_NULL                    =  0
const BLOCKTYPE_PLAIN_MESH              =  1
const BLOCKTYPE_POINT_MESH              =  2
const BLOCKTYPE_PLAIN_VARIABLE          =  3
const BLOCKTYPE_POINT_VARIABLE          =  4
const BLOCKTYPE_CONSTANT                =  5
const BLOCKTYPE_ARRAY                   =  6
const BLOCKTYPE_RUN_INFO                =  7
const BLOCKTYPE_SOURCE                  =  8
const BLOCKTYPE_STITCHED_TENSOR         =  9
const BLOCKTYPE_STITCHED_MATERIAL       = 10
const BLOCKTYPE_STITCHED_MATVAR         = 11
const BLOCKTYPE_STITCHED_SPECIES        = 12
const BLOCKTYPE_SPECIES                 = 13
const BLOCKTYPE_PLAIN_DERIVED           = 14
const BLOCKTYPE_POINT_DERIVED           = 15
const BLOCKTYPE_CONTIGUOUS_TENSOR       = 16
const BLOCKTYPE_CONTIGUOUS_MATERIAL     = 17
const BLOCKTYPE_CONTIGUOUS_MATVAR       = 18
const BLOCKTYPE_CONTIGUOUS_SPECIES      = 19
const BLOCKTYPE_CPU_SPLIT               = 20
const BLOCKTYPE_STITCHED_OBSTACLE_GROUP = 21
const BLOCKTYPE_UNSTRUCTURED_MESH       = 22
const BLOCKTYPE_STITCHED                = 23
const BLOCKTYPE_CONTIGUOUS              = 24
const BLOCKTYPE_LAGRANGIAN_MESH         = 25
const BLOCKTYPE_STATION                 = 26
const BLOCKTYPE_STATION_DERIVED         = 27
const BLOCKTYPE_DATABLOCK               = 28
const BLOCKTYPE_NAMEVALUE               = 29

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
  next_block_location   
  data_location         
  id                  
  data_length         
  block_type          
  data_type           
  n_dims              
  name
end

abstract type AbstractDataHeader end

struct ConstantDataHeader <: AbstractDataHeader
  header::BlockHeader
end

struct PlainVariableDataHeader <: AbstractDataHeader
  header::BlockHeader
end

function header!(f)
  sdf_magic             = String(read(f, 4))
  endianness            = read(f, Int32)
  version               = read(f, Int32)
  revision              = read(f, Int32)
  code_name             = rstrip(String(read(f, ID_LENGTH)))
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
  end
end

function read_constant!(f, d_type)
  read(f, d_type)
end

function read_variable_common!(f)
  mult    = read(f, Float64)
  units   = rstrip(String(read(f, ID_LENGTH)))
  mesh_id = rstrip(String(read(f, ID_LENGTH)))
  (mult, units, mesh_id)
end

function read_plain_variable!(f, d_type, data_location, n_dims)
  mult, units, mesh_id = read_variable_common!(f)

  npts = reinterpret(Int32, read(f, n_dims*sizeof(Int32)))
  dims = prod(npts)
  stagger = read(f, Int32)

  # println("$mult \t $units \t $mesh_id \t $npts \t $stagger\t$dims\t$d_type\t$data_location")
  seek(f, data_location)
  reinterpret(d_type, read(f, dims*sizeof(d_type)))
end

function read_point_variable!(f, d_type, data_location)
  mult, units, mesh_id = read_variable_common!(f)
  npart   = read(f, Int64)

  # println("$mult \t $units \t $mesh_id \t $npart \t $d_type \t $data_location")
  seek(f, data_location)
  reinterpret(d_type, read(f, npart*sizeof(d_type)))
end

function read_mesh_common!(f, n)
  labels  = Array{String}(undef, n)
  units   = Array{String}(undef, n)
  
  mults = reinterpret(Float64, read(f, n*sizeof(Float64)))

  for i = 1:n
    labels[i] = rstrip(String(read(f, ID_LENGTH)))
  end
  for i = 1:n
    units[i] = rstrip(String(read(f, ID_LENGTH)))
  end
  geometry = read(f, Int32)
  extents = reinterpret(Float64, read(f, 2*n*sizeof(Float64)))

  (mults, labels, units, geometry, extents)
end

function read_plain_mesh!(f, d_type, data_location, data_length, n)
  mults, labels, units, geometry, extents = read_mesh_common!(f, n)

  npts = reinterpret(Int32, read(f, n*sizeof(Int32)))
  n_elems = sum(npts)  # prod?
  type_size = div(data_length, n_elems)
  offset = data_location
  for i = 1:n
    #seek(f, offset)
    #read(f, npts[i] n_elems)
    print(offset, " ")
    offset = offset + type_size*npts[i]
  end
  println(" $geometry\t$mults\t$labels\t$units\t$extents\t$npts")
  (data_location, d_type, n_elems)
end

function read_point_mesh!(f, d_type, data_location, data_length, n)
  mults, labels, units, geometry, extents = read_mesh_common!(f, n)

  npart = read(f, Int64)

  n_elems = n*npart # ??
  type_size = div(data_length, n_elems)
  offset = data_location
  for i = 1:n
    #seek(f, offset)
    #read(f, npts[i] n_elems)
    print(offset, " ")
    offset = offset + type_size*npart
  end
  println(" $geometry\t$mults\t$labels\t$units\t$extents\t$npart")
  (data_location, d_type, n_elems)
end

function read_run_info!(f)
  code_version    = read(f, Int32)
  code_revision   = read(f, Int32)
  commit_id       = rstrip(String(read(f, ID_LENGTH)))
  sha1sum         = rstrip(String(read(f, ID_LENGTH)))
  compile_machine = rstrip(String(read(f, ID_LENGTH)))
  compile_flags   = rstrip(String(read(f, ID_LENGTH)))
  defines         = read(f, Int64)
  compile_date    = read(f, Int32)
  run_date        = read(f, Int32)
  io_date         = read(f, Int32)
  println("$code_version, $code_revision, $commit_id, $sha1sum, $compile_machine, $compile_flags, $defines, $compile_date, $run_date, $io_date")
  nothing
end

function n(filename)
  open(filename, "r") do f
    r = header!(f)

    block_start = r.first_block_location
    println("nxt_bl\tdat_loc\tdat_len\tblk_typ\tdt_typ\tndims\tvar\t\t\t\t\t\tid")
    for i = 1:r.nblocks
      seek(f, block_start)
      next_block_location = read(f, UInt64)
      data_location       = read(f, UInt64)
      id                  = rstrip(String(read(f, ID_LENGTH)))
      data_length         = read(f, UInt64)
      block_type          = read(f, UInt32)
      data_type           = read(f, UInt32)
      n_dims              = convert(Int64, read(f, UInt32))
      name                = rstrip(String(read(f, r.string_length)))

      seek(f, block_start + r.block_header_length)
      d_type = type_from(data_type)

      var = if block_type == BLOCKTYPE_CONSTANT
              read_constant!(f, d_type)
            elseif block_type == BLOCKTYPE_PLAIN_VARIABLE
              read_plain_variable!(f, d_type, data_location, n_dims)
            elseif block_type == BLOCKTYPE_POINT_VARIABLE
              read_point_variable!(f, d_type, data_location)
            elseif block_type == BLOCKTYPE_PLAIN_MESH
              read_plain_mesh!(f, d_type, data_location, data_length, n_dims)
            elseif block_type == BLOCKTYPE_POINT_MESH
              read_point_mesh!(f, d_type, data_location, data_length, n_dims)
            elseif block_type == BLOCKTYPE_RUN_INFO
              read_run_info!(f)
            #elseif block_type == BLOCKTYPE_CPU_SPLIT
            #  read_cpu_split!(f, d_type, data_location)
            end
      println("$next_block_location \t $data_location\t$data_length \t $block_type \t $data_type \t $n_dims\t$var\t$id")
      block_start = next_block_location
    end
    r
  end
end

function m()
  n(ARGS[1])
end
