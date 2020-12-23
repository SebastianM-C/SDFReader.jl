struct Data end
struct Grid end
struct StaggeredField end
struct Variable end

data_kind(::Type{<:PlainVariableBlockHeader}) = Data()
data_kind(::Type{<:PointVariableBlockHeader}) = Data()
data_kind(::Type{<:PlainMeshBlockHeader}) = Grid()
data_kind(::Type{<:PointMeshBlockHeader}) = Grid()

discretization_type(::Type{<:PlainVariableBlockHeader}) = StaggeredField()
discretization_type(::Type{<:PlainMeshBlockHeader}) = StaggeredField()
discretization_type(::Type{<:PointVariableBlockHeader}) = Variable()
discretization_type(::Type{<:PointMeshBlockHeader}) = Variable()
