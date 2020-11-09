# SDFReader

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SebastianM-C.github.io/SDFReader.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SebastianM-C.github.io/SDFReader.jl/dev)
![https://www.tidyverse.org/lifecycle/#experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

[EPOCH](https://cfsa-pmw.warwick.ac.uk/mediawiki/index.php/EPOCH:FAQ) is a code for plasma physics simulations using the Particle-in-Cell method. The simulation results are written is .sdf binary files. Several readers for this files are available at https://cfsa-pmw.warwick.ac.uk/SDF. This package intends to be another reader for the .sdf file type.

## Quick start

Install the package using
```
] add SDFReader
```

Assuming that you have a `.sdf` file generated from an EPOCH simulation,
use `file_summary` to get an overview of the data stored in the file.

```julia
using SDFReader

dir = "my_simulation"
file = "0002.sdf"
blocks = file_summary(joinpath(dir, file))
```

This will give the dictionary of blocks that correspond to the information
represented by the keys. In order to read the data, you can use the
`readkeys` function. Here is an example

```julia
keys = ["weight/electron",
        "grid/electron",
        "py/electron",
        "pz/electron"]

w, (x,y,z), py, pz = readkeys(file, blocks, keys)
```
The returned arrays will have the stored values and the corresponding units
(via Unitful.jl).

For more information regarding the information contained in the `.sdf` files,
please consult the EPOCH documentation.
