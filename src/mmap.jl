abstract type AbstractMmapedEntry{T,N} <: AbstractArray{T,N} end

struct MmapedVariable{T,N,B<:AbstractBlockHeader{T,N},I,M} <: AbstractMmapedEntry{T,N}
    block::B
    chunksize::NTuple{N,Int}
    io::I
    mm::M
end

auto_kernel_size(::AbstractBlockHeader{T,1}) where {T} = (100,)
auto_kernel_size(::AbstractBlockHeader{T,2}) where {T} = (50, 50)
auto_kernel_size(::AbstractBlockHeader{T,3}) where {T} = (20, 20, 20)

function MmapedVariable(
    file::IO,
    block::Union{PlainVariableBlockHeader,PointVariableBlockHeader},
    kernel_size=auto_kernel_size(block)
)

    dims = Int.(size(block))
    n = prod(dims) * sizeof(eltype(block))
    offset = get_offset(block)
    chunksize = padded_tilesize(Float64, kernel_size)

    mm = mmap(file, Vector{UInt8}, n, offset)
    restored_type_mm = reinterpret(eltype(block), mm)
    reshapd_mm = reshape(restored_type_mm, dims)

    MmapedVariable(block, chunksize, file, reshapd_mm)
end

# PlainMeshBlockHeader is the mesh given by the "grid" block (the grid for fields),
# there's no need to mmap it, we can just represtent it with a range

struct MmapedParticleMesh{T,N,B<:PointMeshBlockHeader{T,N},I,M} <: AbstractMmapedEntry{T,1}
    block::B
    chunksize::Tuple{Int}
    axis::Int
    io::I
    mm::M
end

Base.size(pm::MmapedParticleMesh) = (size(pm.block, pm.axis),)

function MmapedParticleMesh(file::IO, block::PointMeshBlockHeader, axis::Int, kernel_size=(1000,))
    dims = Int(size(block, axis))
    n = dims * sizeof(eltype(block))
    offset = get_offset(block, axis)
    chunksize = padded_tilesize(Float64, kernel_size)

    mm = mmap(file, Vector{UInt8}, n, offset)
    restored_type_mm = reinterpret(eltype(block), mm)

    MmapedParticleMesh(block, chunksize, axis, file, restored_type_mm)
end

# AbstractArray interface
Base.size(ame::AbstractMmapedEntry) = size(ame.block)
Base.IndexStyle(::Type{<:AbstractMmapedEntry}) = IndexLinear()
Base.@propagate_inbounds Base.getindex(ame::AbstractMmapedEntry, i::Int) = ame.mm[i]

# TiledIteration
TiledIteration.TileIterator(ame::AbstractMmapedEntry) = TileIterator(axes(ame), ame.chunksize)
TiledIteration.SplitAxis(ame::AbstractMmapedEntry, d) = SplitAxis(axes(ame, d), ame.chunksize[d])

mmap_block(file::IO, block::Union{PlainVariableBlockHeader,PointVariableBlockHeader}, ks=auto_kernel_size(block)) = MmapedVariable(file, block, ks)
mmap_block(file::IO, block::PointMeshBlockHeader, ax, ks=(1000,)) = MmapedParticleMesh(file, block, ax, ks)
mmap_block(::IO, ::PlainMeshBlockHeader, args...) = error("There is no need to mmap this block type.")
mmap_block(args...) = error("Unknown block type")
