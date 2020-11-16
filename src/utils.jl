get_time(file) = open(file) do f
    h = header(file)
    h.time * u"s"
end

function get_normalization(block::T) where T
    get_normalization(isgrid(T), block)
end

get_normalization(::Variable, block) = block.mult
get_normalization(::Mesh, block) = block.mults

