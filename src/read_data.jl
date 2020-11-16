function Base.read!(f, block::ConstantBlockHeader{T}) where T
    block.val
end

function Base.read!(f, block::PlainMeshBlockHeader{T,D}) where {T,D}
    offset = block.base_header.data_location

    raw_data = ntuple(Val(D)) do i
        Array{T, 1}(undef, block.dims[i])
    end
    @inbounds for i in eachindex(raw_data)
        seek(f, offset)
        offset += sizeof(T) * block.dims[i]
        read!(f, raw_data[i])
    end

    return raw_data
end

function Base.read!(f, block::PointMeshBlockHeader{T,D}) where {T,D}
    offset = block.base_header.data_location

    raw_data = ntuple(Val(D)) do _
        Array{T, 1}(undef, block.np)
    end
    @inbounds for i in eachindex(raw_data)
        seek(f, offset)
        offset += sizeof(T) * block.np
        read!(f, raw_data[i])
    end

    return raw_data
end

function Base.read!(f, block::PlainVariableBlockHeader{T}) where T
    dim = prod(block.dims)
    raw_data = Array{T, 1}(undef, dim)

    seek(f, block.base_header.data_location)
    read!(f, raw_data)

    reshape(raw_data, block.dims)
end

function Base.read!(f, block::PointVariableBlockHeader{T}) where T
    raw_data = Array{T, 1}(undef, block.np)
    seek(f, block.base_header.data_location)

    read!(f, raw_data)
end

function Base.read!(f, block::RunInfoBlockHeader{T,D}) where {T,D}
end
