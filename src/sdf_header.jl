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
    d_type::Union{
        Type{Nothing},
        Type{Float32},
        Type{Float64},
        Type{Int32},
        Type{Int64},
    }
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
    npts::NTuple{N,Int32}
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

    mults::Array{Float64,N}
    labels::Array{String,N}
    units::Array{String,N}
    geometry::Int32
    minval::Array{Float64,N}
    maxval::Array{Float64,N}
    npts::Array{Int32,N}
end

struct PointMeshBlockHeader{N} <: AbstractBlockHeader
    base_header::BlockHeader

    mults::Array{Float64,N}
    labels::Array{String,N}
    units::Array{String,N}
    geometry::Int32
    minval::Array{Float64,N}
    maxval::Array{Float64,N}
    npart::Int64
end

struct CPUInfoBlockHeader <: AbstractBlockHeader
    base_header::BlockHeader
end

function header!(f)
    sdf_magic = String(read(f, 4))
    endianness = read(f, Int32)
    version = read(f, Int32)
    revision = read(f, Int32)
    code_name = (String(read(f, ID_LENGTH)))
    first_block_location = read(f, Int64)
    summary_location = read(f, Int64)
    summary_size = read(f, Int32)
    nblocks = read(f, Int32)
    block_header_length = read(f, Int32)
    sym_step = read(f, Int32)
    sym_time = read(f, Float64)
    jobid1 = read(f, Int32)
    jobid2 = read(f, Int32)
    string_length = read(f, Int32)
    code_io_version = read(f, Int32)

    Header(
        sdf_magic,
        endianness,
        version,
        revision,
        code_name,
        first_block_location,
        summary_location,
        summary_size,
        nblocks,
        block_header_length,
        sym_step,
        sym_time,
        jobid1,
        jobid2,
        string_length,
        code_io_version,
    )
end

function read_header!(f, block, ::Val{BLOCKTYPE_CONSTANT})
    ConstantBlockHeader(block)
end

function read_header!(f, block, ::Val{BLOCKTYPE_PLAIN_VARIABLE})
    mult, units, mesh_id = read_variable_common!(f)

    npts = reinterpret(Int32, read(f, block.n_dims * sizeof(Int32)))
    stagger = read(f, Int32)

    PlainVariableBlockHeader(block, mult, units, mesh_id, Tuple(npts), stagger)
end

function read_header!(f, block, ::Val{BLOCKTYPE_POINT_VARIABLE})
    mult, units, mesh_id = read_variable_common!(f)
    npart = read(f, Int64)

    PointVariableBlockHeader(block, mult, units, mesh_id, npart)
end

function read_header!(f, block, ::Val{BLOCKTYPE_PLAIN_MESH})
    mults, labels, units, geometry, minval, maxval = read_mesh_common!(
        f,
        block.n_dims,
    )
    npts = reinterpret(Int32, read(f, block.n_dims * sizeof(Int32)))

    PlainMeshBlockHeader(
        block,
        Array(mults),
        labels,
        units,
        geometry,
        Array(minval),
        Array(maxval),
        Array(npts),
    )
end

function read_header!(f, block, ::Val{BLOCKTYPE_POINT_MESH})
    mults, labels, units, geometry, minval, maxval = read_mesh_common!(
        f,
        block.n_dims,
    )
    npart = read(f, Int64)

    PointMeshBlockHeader(
        block,
        Array(mults),
        labels,
        units,
        geometry,
        Array(minval),
        Array(maxval),
        npart,
    )
end

function read_header!(f, block, ::Val{BLOCKTYPE_RUN_INFO})
    code_version = read(f, Int32)
    code_revision = read(f, Int32)
    commit_id = String(read(f, ID_LENGTH))
    sha1sum = String(read(f, ID_LENGTH))
    compile_machine = String(read(f, ID_LENGTH))
    compile_flags = String(read(f, ID_LENGTH))
    defines = read(f, Int64)
    compile_date = read(f, Int32)
    run_date = read(f, Int32)
    io_date = read(f, Int32)

    CPUInfoBlockHeader(block)
end

function read_header!(f, block, ::Val{BLOCKTYPE_CPU_SPLIT})
    CPUSplitBlockHeader(block)
end

function read_variable_common!(f)
    mult = read(f, Float64)
    units = String(read(f, ID_LENGTH))
    mesh_id = String(read(f, ID_LENGTH))

    (mult, units, mesh_id)
end

function read_mesh_common!(f, n)
    labels = Array{String}(undef, n)
    units = Array{String}(undef, n)

    mults = reinterpret(Float64, read(f, n * sizeof(Float64)))

    for i = 1:n
        labels[i] = String(read(f, ID_LENGTH))
    end
    for i = 1:n
        units[i] = String(read(f, ID_LENGTH))
    end
    geometry = read(f, Int32)
    minval = reinterpret(Float64, read(f, n * sizeof(Float64)))
    maxval = reinterpret(Float64, read(f, n * sizeof(Float64)))

    (mults, labels, units, geometry, minval, maxval)
end
