function get_normalization(block::T) where T
    get_normalization(data_kind(T), block)
end

get_normalization(::Data, block) = block.mult
get_normalization(::Grid, block) = block.mults

# https://github.com/JuliaLang/Statistics.jl/pull/28
@static if VERSION < v"1.6.0"
    Statistics.middle(x::Number, y::Number) = x/2 + y/2
end
