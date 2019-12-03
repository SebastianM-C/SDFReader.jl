using Documenter, SDFReader

makedocs(;
    modules=[SDFReader],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/SebastianM-C/SDFReader.jl/blob/{commit}{path}#L{line}",
    sitename="SDFReader.jl",
    authors="Sebastian Micluța-Câmpeanu <m.c.sebastian95@gmail.com>",
    assets=String[],
)
