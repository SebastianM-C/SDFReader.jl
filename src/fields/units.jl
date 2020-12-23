for F in (:ScalarField,:VectorField,:ScalarVariable,:VectorVariable)
    @eval begin
        function Unitful.ustrip(f::T) where T <: $F
            data = map(ustrip, f.data)
            grid = map(ustrip, f.grid)

            ($F)(data, grid)
        end
    end
end

for F in (:ScalarField,:VectorField,:ScalarVariable,:VectorVariable)
    for f in (:uconvert, :ustrip)
        @eval begin
            function (Unitful.$f)(u_data::Units, f::T) where T <: $F
                data = map(d->($f)(u_data, d), f.data)
                grid = f.grid

                ($F)(data, grid)
            end

            function (Unitful.$f)(u_data::Units, u_grid::Units, f::T) where T <: $F
                data = map(d->($f)(u_data, d), f.data)
                grid = map.(d->($f)(u_grid, d), f.grid)

                ($F)(data, grid)
            end
        end
    end
end
