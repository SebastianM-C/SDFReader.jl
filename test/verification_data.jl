module VerificationData

export create_dicts

using PyCall
using Serialization

const sdf = PyNULL()
const sh = PyNULL()

function __init__()
    copy!(sdf, pyimport("sdf"))
    copy!(sh, pyimport("sdf_helper"))
end

function convert_it(read_only_numpy_arr::PyObject)
    # See https://github.com/JuliaPy/PyCall.jl/blob/master/src/pyarray.jl#L14-L24

    # instead of PyBUF_ND_STRIDED =  Cint(PyBUF_WRITABLE | PyBUF_FORMAT | PyBUF_ND | PyBUF_STRIDES)
    # See https://github.com/JuliaPy/PyCall.jl/blob/master/src/pybuffer.jl#L113
    pybuf = PyBuffer(read_only_numpy_arr, PyCall.PyBUF_FORMAT | PyCall.PyBUF_ND | PyCall.PyBUF_STRIDES)

    T, native_byteorder = PyCall.array_format(pybuf)
    sz = size(pybuf)
    strd = PyCall.strides(pybuf)
    length(strd) == 0 && (sz = ())
    N = length(sz)
    isreadonly = pybuf.buf.readonly==1
    info = PyCall.PyArray_Info{T,N}(native_byteorder, sz, strd, pybuf.buf.buf, isreadonly, pybuf)

    # See https://github.com/JuliaPy/PyCall.jl/blob/master/src/pyarray.jl#L123-L126
    PyCall.PyArray{T,N}(read_only_numpy_arr, info)
end

function filereader(path; convert=false)
    sdf.read(path, convert=convert)
end

convert_variable(py_data::Tuple) = Array.(convert_it.(py_data))
convert_variable(py_data::PyObject) = Array(convert_it(py_data))
convert_variable(py_data) = py_data

function get_grid(py_obj, data_size)
    grid = convert_it.(py_obj.grid.data)
    if data_size[1] == length.(grid)[1]
        return Array.(grid)
    else
        grid_mid = Array.(convert_it.(py_obj.grid_mid.data))
        return grid_mid
    end
end

function create_dicts(fn)
    fr = filereader(fn)
    variables = filter!(k->!startswith(k, "__"), String.(keys(fr)))
    data = Dict{String, Any}()
    grids = Dict{String, NTuple{3,Vector}}()
    units = Dict{String, Union{String,Tuple{String},NTuple{3,String}}}()
    for v in variables
        sdf_var = getproperty(fr, v)
        if hasproperty(sdf_var, :data)
            data[v] = convert_variable(sdf_var.data)
            if hasproperty(sdf_var, :grid)
                grids[v] = get_grid(sdf_var, size(data[v]))
            end
        end
        if hasproperty(sdf_var, :units)
            units[v] = sdf_var.units
        end
    end

    return data, grids, units
end

function create_dicts()
    serialize("0002.jl", create_dicts("0002.sdf"))
end

end  # module VerificationData
