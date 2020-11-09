struct ParticleVariable{T,N,A} <: AbstractQuantity
    data::Array{T, 1}
    grid::NTuple{N, A}
end

function ParticleVariable(data::Array{T,N}, grid, units::Units{U,D}) where {T,N,D,U}
    ParticleVariable(data*units, grid)
end

function ParticleVariable(x::Array{T,N}, y::Array{T,N}, grid, units::Units{U,D}) where {T,N,D,U}
    data = Point{2,T}.(x, y)
    ParticleVariable(data*units, grid)
end

function ParticleVariable(x::Array{T,N}, y::Array{T,N}, z::Array{T,N}, grid, units::Units{U,D}) where {T,N,D,U}
    data = Point{3,T}.(x, y, z)
    ParticleVariable(data*units, grid)
end

function ParticleVariable(fn::AbstractString, block::AbstractBlockHeader)
    data = read!(fn, block)
    if data isa Tuple
        units = get_units.(block.units)
        @assert length(unique(units)) == 1
        ParticleVariable(data..., units[1])
    else
        units = get_units(block.units)
        ParticleVariable(data, units)
    end
end
