function read_data!(f, block, ::Val{BLOCKTYPE_CONSTANT})
    read(f, block.d_type)
end

function read_variable_common!(f)
    mult = read(f, Float64)
    units = String(read(f, ID_LENGTH))
    mesh_id = String(read(f, ID_LENGTH))

    (mult, units, mesh_id)
end

function read_data!(f, block, ::Val{BLOCKTYPE_PLAIN_VARIABLE})
    dims = prod(block.npts)
    seek(f, block.base_header.data_location)

    raw_data = read(f, dims * sizeof(block.base_header.d_type))
    reshape(Array(reinterpret(block.base_header.d_type, raw_data)), block.npts)
end

function read_data!(f, block, ::Val{BLOCKTYPE_POINT_VARIABLE})
    seek(f, block.data_location)

    reinterpret(block.d_type, read(f, block.npart * sizeof(block.d_type)))
end

function read_mesh_common!(f, n)
    labels = Array{String}(undef, n)
    units = Array{String}(undef, n)

    mults = reinterpret(Float64, read(f, n * sizeof(Float64)))

    for i = 1:n
        labels[i] = String(read(f, ID_LENGTH))
    end
    for i = 1:n
        units[i] = String(read(f, ID_LENGTH))
    end
    geometry = read(f, Int32)
    minval = reinterpret(Float64, read(f, n * sizeof(Float64)))
    maxval = reinterpret(Float64, read(f, n * sizeof(Float64)))

    (mults, labels, units, geometry, minval, maxval)
end

function read_plain_mesh!(f, d_type, data_location, data_length, n)
    n_elems = sum(npts)  # prod?
    type_size = div(data_length, n_elems)
    offset = data_location
    for i = 1:n
    #seek(f, offset)
    #read(f, npts[i] n_elems)
    # print(offset, " ")
        offset = offset + type_size * npts[i]
    end

    (data_location, d_type, n_elems)
end

function read_point_mesh!(f, d_type, data_location, data_length, n)
    mults, labels, units, geometry, minval, maxval = read_mesh_common!(f, n)

    npart = read(f, Int64)

    n_elems = n * npart # ??
    type_size = div(data_length, n_elems)
    offset = data_location
    for i = 1:n
    #seek(f, offset)
    #read(f, npts[i] n_elems)
    # print(offset, " ")
        offset = offset + type_size * npart
    end

    (data_location, d_type, n_elems)
end
