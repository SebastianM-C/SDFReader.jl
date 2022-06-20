struct SDFVariable{T,N,B,S} <: AbstractDiskArray{T,N}
    stream::S
    block::B
    chunksize::NTuple{N,Int}
end

function SDFVariable{T}(file::S, block::B, chunksize::NTuple{N,Int}) where {T,N,B,S}
    SDFVariable{T,N,B,S}(file, block, chunksize)
end

function SDFVariable(file::IOStream, block::AbstractBlockHeader; chunksize=Int.(size(block)))
    SDFVariable{eltype(block)}(file, block, chunksize)
end

struct SDFMesh{T,N,B,S} <: AbstractDiskArray{T,N}
    stream::S
    block::B
    axis::Int
    chunksize::NTuple{N,Int}
end

function SDFMesh{T}(file::S, block::B, axis, chunksize::NTuple{N,Int}) where {T,N,B,S}
    SDFMesh{T,N,B,S}(file, block, axis, chunksize)
end

function SDFMesh(file::IOStream, block::AbstractBlockHeader, axis; chunksize=(Int(size(block, axis)),))
    SDFMesh{eltype(block)}(file, block, axis, chunksize)
end

haschunks(::SDFVariable) = Chunked()
haschunks(::SDFMesh) = Chunked()

Base.size(a::SDFVariable) = size(a.block)
Base.size(a::SDFMesh) = (size(a.block)[a.axis],)

function check_continuous(linear_idxs)
    vec_idxs = vec(linear_idxs)
    @debug "Linear indices to read: $linear_idxs"
    length(linear_idxs) == 1 && return nothing
    mapreduce(isone, &, diff(vec_idxs, dims=1)) || error("Can only read contiguous regions.")
    return nothing
end

function readchunk!(stream, aout, linear_idxs, T, offset)
    check_continuous(linear_idxs)

    start_idx = first(linear_idxs)
    n = length(linear_idxs)
    @debug "Starting to read $n elements of type $T from $start_idx"

    target_nb = sizeof(T) * n
    raw_data = reinterpret(UInt8, vec(aout))

    seek(stream, offset + (start_idx - 1) * sizeof(T))
    nb = readbytes!(stream, raw_data, target_nb)

    target_nb ≠ nb && @warn "Read only $nb bytes instead of $target_nb"
    return nothing
end

# This covers PointVariableBlockHeader and PlainVariableBlockHeader
function DiskArrays.readblock!(a::SDFVariable, aout, idxs::AbstractUnitRange...)
    ndims(a) == length(idxs) || error("Number of indices is not correct")
    all(r -> isa(r, AbstractUnitRange), idxs) || error("Not all indices are unit ranges")

    stream, block = a.stream, a.block
    linear_idxs = LinearIndices(a)[idxs...]
    offset = get_offset(block)
    readchunk!(stream, aout, linear_idxs, eltype(block), offset)
end

function DiskArrays.readblock!(a::SDFMesh{T,N,B}, aout, idxs::AbstractUnitRange) where {T,N,B<:PointMeshBlockHeader}
    stream, block = a.stream, a.block
    offset = get_offset(block)
    axis = a.axis
    offset += sizeof(T) * block.np * (axis - 1)
    readchunk!(stream, aout, idxs, T, offset)
end

function DiskArrays.readblock!(a::SDFMesh{T,N,B}, aout, idxs::AbstractUnitRange) where {T,N,B<:PlainMeshBlockHeader}
    stream, block = a.stream, a.block
    offset = get_offset(block)
    axis = a.axis
    offset += sizeof(T) * block.dims[axis] * (axis - 1)
    readchunk!(stream, aout, idxs, T, offset)
end
