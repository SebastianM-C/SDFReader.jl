function Base.read(f, block::ConstantBlockHeader)
    read(f, block.d_type)
end

function Base.read!(f, block::PlainVariableBlockHeader)
    dims = prod(block.npts)
    raw_data = Array{block.base_header.d_type, 1}(undef, dims)

    seek(f, block.base_header.data_location)
    read!(f, raw_data)

    reshape(raw_data, block.npts)
end

function Base.read!(f, block::PointVariableBlockHeader)
    raw_data = Array{block.base_header.d_type, 1}(undef, block.npart)
    seek(f, block.base_header.data_location)

    read!(f, raw_data)
end

function Base.read!(f, block::PlainMeshBlockHeader)
    d_type = block.base_header.d_type
    offset = block.base_header.data_location

    ntuple(block.base_header.n_dims) do i
        raw_data = Array{d_type, 1}(undef, block.npts[i])
        seek(f, offset)
        offset += sizeof(d_type) * block.npts[i]
        read!(f, raw_data)
    end
end

function Base.read!(f, block::PointMeshBlockHeader)
    d_type = block.base_header.d_type
    offset = block.base_header.data_location

    ntuple(block.base_header.n_dims) do _
        raw_data = Array{d_type, 1}(undef, block.npart)
        seek(f, offset)
        offset += sizeof(d_type) * block.npart
        read!(f, raw_data)
    end
end
