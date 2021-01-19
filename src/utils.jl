function get_normalization(block::T) where T
    get_normalization(data_kind(T), block)
end

get_normalization(::Data, block) = block.mult
get_normalization(::Grid, block) = block.mults
