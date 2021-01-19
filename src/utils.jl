function get_normalization(block::T) where T
    hasproperty(block, :mult) ? block.mult : block.mults
end
