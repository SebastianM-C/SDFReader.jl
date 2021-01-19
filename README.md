# SDFReader

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SebastianM-C.github.io/SDFReader.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SebastianM-C.github.io/SDFReader.jl/dev)
[![Build Status](https://github.com/SebastianM-C/SDFReader.jl/workflows/CI/badge.svg)](https://github.com/SebastianM-C/SDFReader.jl/actions)
![https://www.tidyverse.org/lifecycle/#experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

[EPOCH](https://cfsa-pmw.warwick.ac.uk/mediawiki/index.php/EPOCH:FAQ) is a code for plasma physics simulations using the Particle-in-Cell method. The simulation results are written is `.sdf` binary files. Several readers for this files are available at https://cfsa-pmw.warwick.ac.uk/SDF.
This package intends to be another reader for the `.sdf` file type providing low level acces to the data by following the [SDF file format documentation](https://cfsa-pmw.warwick.ac.uk/SDF/SDF_documentation).
For a more user firendly approach, please use [SDFResults](https://github.com/SebastianM-C/SDFResults.jl).

## Quick start

Install the package using
```
]add SDFReader
```

The metadata in the `.sdf` files can be accessed with the `file_summary` function
```julia
blocks = file_summary(filename)
```
This will return a dictionary that can be used to access the block headers corrsoponding to the data.
To read the data use
```julia
ex = open(file) do f
    read(f, blocks[:ex])
end
```

For more information regarding the information contained in the `.sdf` files,
please consult the following
* [EPOCH documentation](https://cfsa-pmw.warwick.ac.uk/mediawiki/index.php/EPOCH:Landing_Page)
* [SDF file format documentation](https://cfsa-pmw.warwick.ac.uk/SDF/SDF_documentation)
