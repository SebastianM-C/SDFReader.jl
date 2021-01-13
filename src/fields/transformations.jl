@enum Orientation begin
    AlongX
    AlongY
    AlongZ
end

collect_grid(grid) = grid

function collect_grid(grid::NTuple{N, T}) where {N, T <: AbstractRange}
    map(idxs->SVector{N}(idxs...), Iterators.product(grid...))
end

function collect_grid(grid::NTuple{N, T}) where {N, T <: AbstractVector}
    map(idxs->SVector{N}(idxs...), zip(grid...))
end

to_cylindrical(::Val{AlongZ}) = CylindricalFromCartesian()

to_cylindrical(f::AbstractField{3}, o::Orientation) = to_cylindrical(scalarness(f), f, o)

function to_cylindrical(::ScalarQuantity, f, orientation)
    # TODO: Add coordinate system to fields
    # assume cartesian for now
    dense_grid = collect_grid(f.grid)
    t = to_cylindrical(Val(orientation))
    transformed_grid = t.(dense_grid)

    parameterless_type(f)(f.data, transformed_grid)
end
