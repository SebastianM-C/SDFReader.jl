include("files.jl")

struct EPOCHSimulation{P,B}
    dir::String
    files::Vector{SDFFile{P,B}}
    param::P
end

function read_simulation(dir)
    file_list = joinpath(dir, "normal.visit")
    if isfile(file_list)
        paths = readlines(file_list)
    else
        @debug "No normal.visit found in $dir."
        paths = filter(f->endswith(f, ".sdf"), readdir(dir))
    end

    input_deck = joinpath(dir, "input.deck")
    if isfile(input_deck)
        p = parse_input(input_deck)
    else
        @warn "No input.deck found in $dir."
        p = missing
    end

    files = read_file.(joinpath.((dir,), paths), (Ref(p),))

    EPOCHSimulation(dir, files, p)
end

get_parameter(sim::EPOCHSimulation, p::Symbol) = getproperty(sim.param, p)

# Indexing
Base.getindex(sim::EPOCHSimulation, i::Int) = sim.files[i]
Base.firstindex(sim::EPOCHSimulation) = firstindex(sim.files)
Base.lastindex(sim::EPOCHSimulation) = lastindex(sim.files)

# Iteration
Base.iterate(sim::EPOCHSimulation, state...) = iterate(sim.files, state...)
Base.eltype(::Type{EPOCHSimulation}) = SDFFile
Base.length(sim::EPOCHSimulation) = length(sim.files)
