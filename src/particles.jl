function particle_variable(data::PyArray{T,N}, units::Units{U,D}) where {T,N,D,U}
    Array(data*units)
end

function particle_variable(x::PyArray{T,N}, y::PyArray{T,N}, units::Units{U,D}) where {T,N,D,U}
    data = Point{2,T}.(x, y)
    Array(data*units)
end

function particle_variable(x::PyArray{T,N}, y::PyArray{T,N}, z::PyArray{T,N}, units::Units{U,D}) where {T,N,D,U}
    data = Point{3,T}.(x, y, z)
    Array(data*units)
end

function particle_variable(fr::PyObject, key::Symbol)
    py_obj = getproperty(fr, key)
    @debug "Reading data"
    py_data = py_obj.data
    if py_data isa Tuple
        @debug "Converting vector data"
        data = convert_it.(py_data)
        @debug "Reading units"
        units = get_units.(py_obj.units)
        @assert length(unique(units)) == 1
        particle_variable(data..., units[1])
    else
        @debug "Converting scalar data"
        data = convert_it(py_data)
        @debug "Reading units"
        units = get_units(py_obj.units)
        particle_variable(data, units)
    end
end
