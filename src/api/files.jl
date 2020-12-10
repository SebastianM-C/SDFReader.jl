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

function Base.read(sdf::SDFFile, entry::AbstractString)
    open(sdf.name) do f
        read(f, getproperty(sdf.blocks, entry))
    end
end

function Base.read(sdf::SDFFile, entries...)
    open(sdf.name) do f
        asyncmap(i->read(f, getproperty(sdf.blocks,i)), entries)
    end
end

Base.keys(sdf::SDFFile) = keys(sdf.blocks)
function Base.getindex(sdf::SDFFile, idx::Symbol)
    open(sdf.name) do f
        read_scalar_field(f, sdf.blocks, idx)
    end
end

get_parameter(sdf::SDFFile, p::Symbol) = getproperty(sdf.param[], p)

get_time(sdf::SDFFile) = sdf.header.time * u"s"
