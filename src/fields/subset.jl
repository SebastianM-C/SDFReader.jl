function ImageTransformations.imresize(f::AbstractField, target_size::Union{Integer, AbstractUnitRange}...)
    parameterless_type(f)(imresize(f.data, target_size...), resize_grid(f.grid, target_size...))
end

resize_grid(grid::NTuple, target_size...) = imresize.(grid, (target_size...,))
resize_grid(grid::AbstractArray, target_size...) = imresize(grid, target_size...)


function subsample(f::AbstractField, target_size...)
    all(size(f) .> target_size) ? imresize(f, target_size...) : f
end

function dir_to_idx(dir::Symbol)
    if dir === :x
        1
    elseif dir === :y
        2
    elseif dir === :z
        3
    else
        0
    end
end

dir_to_idx(i::Int) = i

function slice(f::ScalarVariable, dir, slice_location, ϵ)
    dim = dir_to_idx(dir)
    idxs = filter(i-> f.grid[dim][i] ∈ slice_location ± ϵ, axes(f.grid[dim], 1))
    data = f.data[idxs]
    grid = f.data[idxs]

    ScalarVariable(data, grid)
end
