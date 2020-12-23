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
    val = read(f, T)
    ConstantBlockHeader(block, val)
end

function Base.read(f, block::BlockHeader{T,N,BLOCKTYPE_PLAIN_MESH}) where {T,N}
    dims = Array{Int32, 1}(undef, N)

    mults, labels, units, geometry, minval, maxval = read_mesh_common!(f,N)
    read!(f, dims)

    PlainMeshBlockHeader(
        block,
        mults,
        labels,
        units,
        geometry,
        minval,
        maxval,
        dims,
    )
end

function Base.read(f, block::BlockHeader{T,N,BLOCKTYPE_POINT_MESH}) where {T,N}
    mults, labels, units, geometry, minval, maxval = read_mesh_common!(f,N)
    np = read(f, Int64)

    PointMeshBlockHeader(
        block,
        mults,
        labels,
        units,
        geometry,
        minval,
        maxval,
        np,
    )
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_PLAIN_VARIABLE}) where {T,D}
    dims = Array{Int32, 1}(undef, D)

    mult, units, mesh_id = read_variable_common!(f)
    read!(f, dims)
    stagger = Stagger(read(f, Int32))

    PlainVariableBlockHeader(block, mult, units, mesh_id, Tuple(dims), stagger)
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_POINT_VARIABLE}) where {T,D}
    mult, units, mesh_id = read_variable_common!(f)
    np = read(f, Int64)

    PointVariableBlockHeader(block, mult, units, mesh_id, np)
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
    # TODO save these fields

    RunInfoBlockHeader(block)
end

function Base.read(f, block::BlockHeader{T,D,BLOCKTYPE_CPU_SPLIT}) where {T,D}
    CPUSplitBlockHeader(block)
end

function read_variable_common!(f)
    mult = read(f, Float64)
    units = simple_str(read(f, ID_LENGTH))
    mesh_id = simple_str(read(f, ID_LENGTH))

    mult, units, mesh_id
end

function read_mesh_common!(f, n)
    minval = Array{Float64, 1}(undef, n)
    maxval = Array{Float64, 1}(undef, n)

    mults = ntuple(n) do i
        read(f, Float64)
    end

    labels = ntuple(n) do i
        simple_str(read(f, ID_LENGTH))
    end
    units = ntuple(n) do i
        simple_str(read(f, ID_LENGTH))
    end
    geometry = Geometry(read(f, Int32))
    read!(f, minval)
    read!(f, maxval)

    mults, labels, units, geometry, minval, maxval
end

simple_str(s) = replace(String(rstrip(String(s))), "\0" => "")
