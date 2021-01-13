function Unitful.ustrip(f::AbstractField)
    data = ustrip.(f.data)
    grid = ustrip_grid(f.grid)

    parameterless_type(f)(data, grid)
end

ustrip_grid(grid::AbstractArray) = ustrip.(grid)
ustrip_grid(grid::NTuple) = map.(ustrip, grid)

for f in (:uconvert, :ustrip)
    @eval begin
        function (Unitful.$f)(u_data::Units, f::AbstractField)
            data = map(d->($f)(u_data, d), f.data)
            grid = f.grid

            parameterless_type(f)(data, grid)
        end

        function (Unitful.$f)(u_data::Units, u_grid::Units, f::AbstractField)
            data = map(d->($f)(u_data, d), f.data)
            grid = map.(d->($f)(u_grid, d), f.grid)

            parameterless_type(f)(data, grid)
        end
    end
end
