using Documenter, SDFReader

makedocs(
    sitename = "SDFReader",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    pages = [
        "index.md",
    ],
    modules = [SDFReader]
)

deploydocs(
    repo = "github.com/SebastianM-C/SDFReader.jl",
    push_preview = true
)
