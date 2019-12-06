using LinearAlgebra

struct Field{T,N,A}
    data::Array{T, N}
    grid::NTuple{N, A}
end

function Field(data, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    Field(data*units, grid)
end

function Field(x, y, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    data = Vec{2,T}.(x, y)
    Field(data*units, grid)
end

function Field(x, y, z, grid::NTuple{N,A}, units::Units{U,D}) where {T,N,A,D,U}
    data = Vec{3,T}.(x, y, z)
    Field(data*units, grid)
end

function Field(fr::PyObject, key::Symbol)
    py_obj = getproperty(fr, key)
    data = convert_it(py_obj.data)
    data_size = size(data)
    units = get_units(py_obj.units)
    grid = convert_it.(py_obj.grid.data)
    if data_size == length.(grid)
        Field(data, grid, units)
    else
        grid_mid = convert_it.(py_obj.grid_mid.data)
        Field(data, grid_mid, units)
    end
end

for f in (:+, :-, :*, :/)
    @eval function (Base.$f)(f1::Field, f2::Field)
        Field(($f).(f1.data, f2.data), f1.grid)
    end
end

function LinearAlgebra.cross(f1::Field, f2::Field)
    Field(cross.(f1.data, f2.data), f1.grid)
end

LinearAlgebra.norm(field::Field) = Field(norm.(field.data), field.grid)
