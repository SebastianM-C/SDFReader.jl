struct Header
    sdf_magic::String
    endianness::Int32
    file_version::Int32
    file_revision::Int32
    code_name::String
    first_block_location::Int64
    summary_location::Int64
    summary_size::Int32
    nblocks::Int32
    block_header_length::Int32
    step::Int32
    time::Float64
    jobid1::Int32
    jobid2::Int32
    string_length::Int32
    code_io_version::Int32
end

struct BlockHeader{T,D,B}
    next_block_location::Int64
    data_location::Int64
    id::String
    data_length::Int64
    name::String
end

function BlockHeader(f::IOStream, start, string_length, header_length)
    seek(f, start)
    next_block_location = read(f, Int64)
    data_location = read(f, Int64)
    id = simple_str(read(f, ID_LENGTH))
    data_length = read(f, Int64)
    block_type = read(f, Int32)
    data_type = read(f, Int32)
    n_dims = read(f, Int32)
    name = simple_str(read(f, string_length))

    d_type = type_from(Val(data_type))
    seek(f, start + header_length)

    BlockHeader{d_type, Int(n_dims), block_type}(
        next_block_location,
        data_location,
        id,
        data_length,
        name,
    )
end

abstract type AbstractBlockHeader{T,D} end

struct ConstantBlockHeader{T,D} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}
end

struct CPUSplitBlockHeader{T,D} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}
end

struct PlainVariableBlockHeader{T,D,N} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}

    mult::Float64
    units::String
    mesh_id::String
    npts::NTuple{N,Int32}
    stagger::Int32
end

struct PointVariableBlockHeader{T,D} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}

    mult::Float64
    units::String
    mesh_id::String
    npart::Int64
end

struct PlainMeshBlockHeader{T,D,N} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}

    mults::Array{Float64,N}
    labels::Array{String,N}
    units::Array{String,N}
    geometry::Int32
    minval::Array{Float64,N}
    maxval::Array{Float64,N}
    npts::Array{Int32,N}
end

struct PointMeshBlockHeader{T,D,N} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}

    mults::Array{Float64,N}
    labels::Array{String,N}
    units::Array{String,N}
    geometry::Int32
    minval::Array{Float64,N}
    maxval::Array{Float64,N}
    npart::Int64
end

struct CPUInfoBlockHeader{T,D} <: AbstractBlockHeader{T,D}
    base_header::BlockHeader{T,D}
end

function header(f::IOStream)
    sdf_magic = simple_str(read(f, 4))
    endianness = read(f, Int32)
    file_version = read(f, Int32)
    file_revision = read(f, Int32)
    code_name = simple_str(read(f, ID_LENGTH))
    first_block_location = read(f, Int64)
    summary_location = read(f, Int64)
    summary_size = read(f, Int32)
    nblocks = read(f, Int32)
    block_header_length = read(f, Int32)
    step = read(f, Int32)
    time = read(f, Float64)
    jobid1 = read(f, Int32)
    jobid2 = read(f, Int32)
    string_length = read(f, Int32)
    code_io_version = read(f, Int32)

    Header(
        sdf_magic,
        endianness,
        file_version,
        file_revision,
        code_name,
        first_block_location,
        summary_location,
        summary_size,
        nblocks,
        block_header_length,
        step,
        time,
        jobid1,
        jobid2,
        string_length,
        code_io_version,
    )
end

header(filename::AbstractString) = open(header, filename)

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_CONSTANT}) where {T,D}
    ConstantBlockHeader(block)
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_PLAIN_VARIABLE}) where {T,D}
    npts = Array{Int32, 1}(undef, D)

    mult, units, mesh_id = read_variable_common!(f)
    read!(f, npts)
    stagger = read(f, Int32)

    PlainVariableBlockHeader(block, mult, units, mesh_id, Tuple(npts), stagger)
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_POINT_VARIABLE}) where {T,D}
    mult, units, mesh_id = read_variable_common!(f)
    npart = read(f, Int64)

    PointVariableBlockHeader(block, mult, units, mesh_id, npart)
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_PLAIN_MESH}) where {T,D}
    npts = Array{Int32, 1}(undef, D)

    mults, labels, units, geometry, minval, maxval = read_mesh_common!(
        f,
        D,
    )
    read!(f, npts)

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

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_POINT_MESH}) where {T,D}
    mults, labels, units, geometry, minval, maxval = read_mesh_common!(
        f,
        D,
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

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_RUN_INFO}) where {T,D}
    code_version = read(f, Int32)
    code_revision = read(f, Int32)
    commit_id = simple_str(read(f, ID_LENGTH))
    sha1sum = simple_str(read(f, ID_LENGTH))
    compile_machine = simple_str(read(f, ID_LENGTH))
    compile_flags = simple_str(read(f, ID_LENGTH))
    defines = read(f, Int64)
    compile_date = read(f, Int32)
    run_date = read(f, Int32)
    io_date = read(f, Int32)

    CPUInfoBlockHeader(block)
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_CPU_SPLIT}) where {T,D}
    CPUSplitBlockHeader(block)
end

function read_variable_common!(f)
    mult = read(f, Float64)
    units = simple_str(read(f, ID_LENGTH))
    mesh_id = simple_str(read(f, ID_LENGTH))

    (mult, units, mesh_id)
end

function read_mesh_common!(f, n)
    mults = Array{Float64, 1}(undef, n)
    labels = Array{String}(undef, n)
    units = Array{String}(undef, n)
    minval = Array{Float64, 1}(undef, n)
    maxval = Array{Float64, 1}(undef, n)

    read!(f, mults)

    for i = 1:n
        labels[i] = simple_str(read(f, ID_LENGTH))
    end
    for i = 1:n
        units[i] = simple_str(read(f, ID_LENGTH))
    end
    geometry = read(f, Int32)
    read!(f, minval)
    read!(f, maxval)

    (mults, labels, units, geometry, minval, maxval)
end

simple_str(s) = replace(String(rstrip(String(s))), "\0" => "")
