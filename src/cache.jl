skipcache(::Any) = false
skipcache(::Type{<:ConstantBlockHeader}) = true
skipcache(::Type{<:RunInfoBlockHeader}) = true
skipcache(::Type{<:CPUSplitBlockHeader}) = true
skipcache(::Type{<:PlainMeshBlockHeader}) = true

function cached_read(f, block, cache)
    skipcache(typeof(block)) && return read(f, block)

    raw_data = get!(cache, (f.name, block)) do
        read!(f, block)
    end

    apply_normalization!(raw_data, block)

    return add_units(raw_data, block)
end
