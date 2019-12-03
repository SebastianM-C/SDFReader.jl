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
