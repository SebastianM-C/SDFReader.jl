function Base.read(f, block::ConstantBlockHeader{T}) where T
    # read(f, type_from(Val(block.d_type)))
    read(f, T)
end

function Base.read!(f, block::PlainVariableBlockHeader{T}) where T
    dims = prod(block.npts)
    raw_data = Array{T, 1}(undef, dims)

    seek(f, block.base_header.data_location)
    read!(f, raw_data)

    reshape(raw_data, block.npts)
end

function Base.read!(f, block::PointVariableBlockHeader{T}) where T
    raw_data = Array{T, 1}(undef, block.npart)
    seek(f, block.base_header.data_location)

    read!(f, raw_data)
end

function Base.read!(f, block::PlainMeshBlockHeader{T,D}) where {T,D}
    offset = block.base_header.data_location

    ntuple(Val(D)) do i
        raw_data = Array{T, 1}(undef, block.npts[i])
        seek(f, offset)
        offset += sizeof(T) * block.npts[i]
        read!(f, raw_data)
    end
end

function Base.read!(f, block::PointMeshBlockHeader{T,D}) where {T,D}
    offset = block.base_header.data_location

    ntuple(Val(D)) do _
        raw_data = Array{T, 1}(undef, block.npart)
        seek(f, offset)
        offset += sizeof(T) * block.npart
        read!(f, raw_data)
    end
end
