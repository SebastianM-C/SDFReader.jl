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

slice(f::T, args...) where T <: AbstractField = slice(domain_discretization(T), domain_type(T), f, args...)

function slice(::ParticleGrid, ::Type{<:Tuple}, f, dir, slice_location, ϵ)
    dim = dir_to_idx(dir)
    idxs = filter(i-> f.grid[dim][i] ∈ slice_location ± ϵ, axes(f.grid[dim], 1))
    data = view(f.data, idxs)
    grid = ntuple(i->f.grid[i][idxs], Val(N))

    parameterless_type(f)(data, grid)
end

function slice(::FixedGrid, ::Type{<:Tuple}, f, dir, slice_location)
    dim = dir_to_idx(dir)
    m, idx = findmin(map(x->abs(x-slice_location), f.grid[dim]))
    data = selectdim(f.data, dim, idx)
    grid = filter(d->d ≠ f.grid[dim], f.grid)

    parameterless_type(f)(data, grid)
end
