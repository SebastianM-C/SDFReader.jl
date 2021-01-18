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

get_parameter(sim::EPOCHSimulation, p::Symbol) = getindex(sim.param, p)
get_parameter(sim::EPOCHSimulation, p::Symbol, c::Symbol) = getindex(get_parameter(sim, p), c)

# Indexing
Base.getindex(sim::EPOCHSimulation, i::Int) = sim.files[i]
Base.firstindex(sim::EPOCHSimulation) = firstindex(sim.files)
Base.lastindex(sim::EPOCHSimulation) = lastindex(sim.files)

# Iteration
Base.iterate(sim::EPOCHSimulation, state...) = iterate(sim.files, state...)
Base.eltype(::Type{EPOCHSimulation}) = SDFFile
Base.length(sim::EPOCHSimulation) = length(sim.files)

# Statistics
function Statistics.mean(f::Function, sim::EPOCHSimulation; cond=x->true)
    ThreadsX.map(sim.files) do file
        println("Loading $(file.name)")
        qunatity = f(file)
        z = zero(eltype(qunatity))
        (qunatity ./ length(qunatity)) |>
            Filter(cond) |>
            foldxt(+, simd=true, init=z)
    end
end

# FileTrees
# FileTrees._maketree(node::SDFFile) = File(nothing, basename(node.name), node)
