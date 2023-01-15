using SDFReader
using Test
using Aqua

@testset "Aqua" begin Aqua.test_all(SDFReader,
                                    ambiguities = (recursive = false)) end

# no non-const globals
non_const_names = filter(x->!isconst(SDFReader, x), names(SDFReader, all = true))
# filter out gensymed names
filter!(x->!startswith(string(x), "#"), non_const_names)
@test isempty(non_const_names)
