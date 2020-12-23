
function Unitful.ustrip(f::AbstractField)
    data = map(ustrip, f.data)
    grid = map(ustrip, f.grid)

    field(f, data, grid)
end

for f in (:uconvert, :ustrip)
    @eval begin
        function (Unitful.$f)(u_data::Units, f::AbstractField)
            data = map(d->($f)(u_data, d), f.data)
            grid = f.grid

            field(f, data, grid)
        end

        function (Unitful.$f)(u_data::Units, u_grid::Units, f::AbstractField)
            data = map(d->($f)(u_data, d), f.data)
            grid = map.(d->($f)(u_grid, d), f.grid)

            field(f, data, grid)
        end
    end
end
