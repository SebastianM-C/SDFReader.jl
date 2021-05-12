function get_normalization(block::T) where T
    hasproperty(block, :mult) ? block.mult : block.mults
end

Base.nameof(block::AbstractBlockHeader) = nameof(block.base_header)

labels(block::PointMeshBlockHeader) = block.labels
labels(block::PlainMeshBlockHeader) = block.labels
