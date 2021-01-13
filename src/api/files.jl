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

get_parameter(sdf::SDFFile, p::Symbol) = getproperty(sdf.param[], p)
get_parameter(sdf::SDFFile, p::Symbol, c::Symbol) = getproperty(get_parameter(sdf, p), c)

get_time(sdf::SDFFile) = sdf.header.time * u"s"
