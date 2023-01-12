function get_normalization(block::T) where {T}
    hasproperty(block, :mult) ? block.mult : block.mults
end

Base.nameof(block::AbstractBlockHeader) = nameof(block.base_header)

labels(block::PointMeshBlockHeader) = block.labels
labels(block::PlainMeshBlockHeader) = block.labels

get_offset(block::AbstractBlockHeader) = block.base_header.data_location
get_offset(block::PointMeshBlockHeader{T}, axis::Int) where {T} = get_offset(block) + sizeof(T) * block.np * (axis - 1)
get_offset(block::PlainMeshBlockHeader{T}, axis::Int) where {T} = get_offset(block) + sizeof(T) * block.dims[axis] * (axis - 1)

function add_units(raw_data::NTuple, block)
    𝟙 = one(eltype(block))
    T = typeof(𝟙 * get_units(block.units)[1])
    map(data -> reinterpret(T, data), raw_data)
end

function add_units(raw_data, block)
    𝟙 = one(eltype(block))
    reinterpret(typeof(𝟙 * get_units(block.units)), raw_data)
end

function apply_normalization!(raw_data, block)
    𝟙 = one(eltype(block))

    n = get_normalization(block)
    if n isa Number
        default_factor = 𝟙
    else
        default_factor = ntuple(one, ndims(block))
    end

    if n ≠ default_factor
        raw_data .*= get_normalization(block)
    end

    return nothing
end
