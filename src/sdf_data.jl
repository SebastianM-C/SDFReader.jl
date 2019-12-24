function Base.read(f, block::ConstantBlockHeader)
    read(f, block.d_type)
end

function Base.read(f, block::PlainVariableBlockHeader)
    dims = prod(block.npts)
    seek(f, block.base_header.data_location)
    raw_data = read(f, dims * sizeof(block.base_header.d_type))

    reshape(Array(reinterpret(block.base_header.d_type, raw_data)), block.npts)
end

function Base.read(f, block::PointVariableBlockHeader)
    seek(f, block.base_header.data_location)
    raw_data = read(f, block.npart * sizeof(block.base_header.d_type))

    Array(reinterpret(block.base_header.d_type, raw_data))
end

function Base.read(f, block::PlainMeshBlockHeader)
    d_type = block.base_header.d_type
    offset = block.base_header.data_location

    ntuple(block.base_header.n_dims) do i
        seek(f, offset)
        offset += sizeof(d_type) * block.npts[i]
        Array(reinterpret(d_type, read(f, block.npts[i]*sizeof(d_type))))
    end
end

function Base.read(f, block::PointMeshBlockHeader)
    d_type = block.base_header.d_type
    offset = block.base_header.data_location

    ntuple(block.base_header.n_dims) do _
        seek(f, offset)
        offset += sizeof(d_type) * block.npart
        Array(reinterpret(d_type, read(f, block.npart*sizeof(d_type))))
    end
end
