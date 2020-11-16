struct Variable end
struct Mesh end

isgrid(::Type{<:PlainVariableBlockHeader}) = Variable()
isgrid(::Type{<:PointVariableBlockHeader}) = Variable()
isgrid(::Type{<:PlainMeshBlockHeader}) = Mesh()
isgrid(::Type{<:PointMeshBlockHeader}) = Mesh()
