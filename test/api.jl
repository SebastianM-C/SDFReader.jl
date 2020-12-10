using Unitful

@testset "Public API tests" begin
    dir = pwd()
    sim = read_simulation(dir)
    @test sim isa EPOCHSimulation
    file = sim[1]
    @test file isa SDFFile
    Ex = sim[1][:ex]
    @test Ex isa ScalarField{3}
    @test all(unit.(Ex.data) .== u"V/m")
    @test all(unit.(Ex.grid[1]) .== u"m")

    vars = (:grid, Symbol("py/electron"), Symbol("pz/electron"))
    @task all(vars .∈ keys(file))
    (x,y,z), py, pz = read(file, vars...)
    @test all(unit.(x) .== u"m")
    @test all(unit.(py) .== u"kg*m/s")

    t = get_time(file)
    @test (t |> u"fs") ≈ 10u"fs" atol = 0.1u"fs"

    nx = get_parameter(file, :nx)
    @test nx == 10
    λ = get_parameter(file, :laser, :lambda)
    @test (λ |> u"nm") ≈ 800u"nm"
end
