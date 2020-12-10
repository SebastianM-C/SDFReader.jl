struct ScalarField{T,G,N} <: AbstractField
    data::AbstractArray{T,N}
    grid::AbstractArray{G,N}
end

function read_scalar_field(file, blocks, name)
    data_block = getproperty(blocks, name)
    data = read(file, data_block)
    mesh_block = getproperty(blocks, Symbol(data_block.mesh_id))
    grid = make_grid(mesh_block, data_block, file)

    ScalarField(data, grid)
end

make_grid(mesh_block::T, data_block, file) where T =
    make_grid(isgrid(T), mesh_block, data_block, file)

function make_grid(::Mesh, mesh_block, data_block, file)
    units = get_units(mesh_block.units)
    minval = mesh_block.minval .* units
    maxval = mesh_block.maxval .* units
    dims = mesh_block.dims

    original_grid = map(eachindex(dims)) do i
        range(minval[i], maxval[i], length=dims[i])
    end

    stagger = data_block.stagger
    grid = apply_stagger(original_grid, Val(stagger))

    # Fix grid in the cases where it doesn't match the data. See
    # https://cfsa-pmw.warwick.ac.uk/SDF/SDF_C/-/blob/master/src/sdf_control.c#L775-780
    for i in axes(grid)[1]
        if length(grid[i]) ≠ data_block.dims[i]
            grid = setindex!!(grid, grid[i][begin:end-1], i)
        end
    end

    return grid
end

function make_grid(::Variable, mesh_block, data_block, file)
    read(file, mesh_block)
end

apply_stagger(grid, ::Val{CellCentre}) = midpoints.(grid)

function apply_stagger(grid, ::Val{FaceX})
    n = length(grid)
    if n == 1
        grid
    # TODO: 2D
    else
        (grid[1], midpoints.(grid[2:end])...)
    end
end

function apply_stagger(grid, ::Val{FaceY})
    n = length(grid)
    if n == 1
        grid
    else
        (midpoints(grid[1]), grid[2], midpoints(grid[3]))
    end
end

function apply_stagger(grid, ::Val{FaceZ})
    n = length(grid)
    if n == 1
        grid
    else
        (midpoints.(grid[1:2])..., grid[3])
    end
end

function apply_stagger(grid, ::Val{EdgeX})
    n = length(grid)
    if n == 1
        grid
    else
        (midpoints(grid[1]), grid[2:end]...)
    end
end

function apply_stagger(grid, ::Val{EdgeY})
    n = length(grid)
    if n == 1
        grid
    else
        (grid[1], midpoints(grid[2]), grid[3])
    end
end

function apply_stagger(grid, ::Val{EdgeZ})
    n = length(grid)
    if n == 1
        grid
    else
        (grid[1:2]..., midpoints(grid[3]))
    end
end

apply_stagger(grid, ::Val{Vertex}) = grid



# for f in (:+, :-, :*, :/)
#     @eval function (Base.$f)(f1::AbstractQuantity, f2::AbstractQuantity)
#         Field(($f).(f1.data, f2.data), f1.grid)
#     end
# end

# function LinearAlgebra.cross(f1::AbstractQuantity, f2::AbstractQuantity)
#     Field(cross.(f1.data, f2.data), f1.grid)
# end
