function get_normalization(block::T) where T
    get_normalization(isgrid(T), block)
end

get_normalization(::Variable, block) = block.mult
get_normalization(::Mesh, block) = block.mults

# https://github.com/JuliaLang/Statistics.jl/pull/28
@static if VERSION < v"1.6.0"
    Statistics.middle(x::Number, y::Number) = x/2 + y/2
end
