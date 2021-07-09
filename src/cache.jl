skipcache(::Any) = false
skipcache(::ConstantBlockHeader) = true
skipcache(::RunInfoBlockHeader) = true
skipcache(::CPUSplitBlockHeader) = true

function cached_read(f, block, cache)
    skipcache(block) && return read(f, block)

    raw_data = get!(cache, (f.name, block)) do
        read!(f, block)
    end

    𝟙 = one(eltype(block))
    if get_normalization(block) ≠ 𝟙
        raw_data .*= get_normalization(block)
    end

    return reinterpret(typeof(𝟙*get_units(block.units)), raw_data)
end
