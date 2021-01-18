struct SDFFile{P,B}
    name::String
    header::Header
    blocks::B
    param::Ref{P}
end

function read_file(file, p)
    h, blocks = open(file_summary, file)
    SDFFile(file, h, blocks, p)
end

function Base.read(sdf::SDFFile, entry::Symbol)
    open(sdf.name) do f
        read(f, getindex(sdf.blocks, entry))
    end
end

function Base.read(sdf::SDFFile, entries...)
    open(sdf.name) do f
        asyncmap(i->read(f, getindex(sdf.blocks,i)), entries)
    end
end

Base.keys(sdf::SDFFile) = keys(sdf.blocks)

function Base.getindex(sdf::SDFFile, idx::Symbol)
    open(sdf.name) do f
        read_entry(f, sdf.blocks, idx)
    end
end

function expensive_grids(ids, idx)
    # Values corresponding to "grid/[species]") are expensive to read
    cid = [ids...]
    for (i, id) in enumerate(ids)
        if isnothing(id) && occursin("grid/", string(idx[i]))
            cid[i] = idx[i]
        end
    end
    s_id = string.(cid)
    expensive = map(i->occursin("grid/", i), s_id)
    !reduce(|, expensive) && return nothing
    @debug "Found expensive to read mesh entries"
    map(Symbol, unique(s_id[expensive])), expensive
end

# The data for the particles is the most expensive to read since there are
# a lot of particles. Since the ScalarVariables have a grid, that grid
# might be the same for more variables and thus could be read only once and
# stored as a Ref.
function Base.getindex(sdf::SDFFile, idx::Vararg{Symbol, N}) where N
    mesh_ids = get_mesh_id.((sdf,), idx)
    @debug "Reading entries for $idx with mesh ids $mesh_ids"
    expensive_ids, is_expensive = expensive_grids(mesh_ids, idx)
    if isnothing(expensive_ids)
        simple_read(sdf, idx)
    else
        @debug "Expensive idxs: $is_expensive"
        @debug "Reading data without expensive grids"
        partial_data = selective_read(sdf, idx, expensive_ids)
        @debug "Reading expensive grids: $expensive_ids"
        grids = open(sdf.name) do f
            asyncmap(i->read(f, sdf.blocks[i]), expensive_ids)
        end
        grid_map = (; zip(expensive_ids, grids)...)
        complete_data = ()
        for (i, d) in enumerate(partial_data)
            @debug "Is $(idx[i]) expensive? $(is_expensive[i])"
            if is_expensive[i]
                id = mesh_ids[i]
                @debug "Expensive grid $id at $i"
                if isnothing(id)
                    grid_id = idx[i]
                    @debug "Storing grid entry $grid_id"
                    # grid = Ref(getproperty(grid_map, grid_id))
                    grid = getproperty(grid_map, grid_id)
                    complete_data = push!!(complete_data, grid)
                else
                    @debug "Storing $id"
                    grid = getproperty(grid_map, id)
                    data = d.data
                    data_block = d.block

                    f = store_entry(data_block, data, grid)
                    complete_data = push!!(complete_data, f)
                end
            else
                complete_data = push!!(complete_data, d)
            end
        end
        complete_data
    end
end

function selective_read(sdf, idx, expensive_ids)
    open(sdf.name) do f
        asyncmap(i->read_selected(f, sdf.blocks, i, expensive_ids), idx)
    end
end

function simple_read(sdf, idx)
    open(sdf.name) do f
        asyncmap(i->read_entry(f, sdf.blocks, i), idx)
    end
end

Base.getindex(sdf::SDFFile, idx::Vararg{AbstractString, N}) where N = sdf[Symbol.(idx)...]

get_parameter(sdf::SDFFile, p::Symbol) = getindex(sdf.param[], p)
get_parameter(sdf::SDFFile, p::Symbol, c::Symbol) = getindex(get_parameter(sdf, p), c)

get_time(sdf::SDFFile) = sdf.header.time * u"s"
get_npart(sdf::SDFFile, species) = sdf.blocks["px/"*species].np
