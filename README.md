# SDFReader

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://SebastianM-C.github.io/SDFReader.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://SebastianM-C.github.io/SDFReader.jl/dev)
![https://www.tidyverse.org/lifecycle/#experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)

[EPOCH](https://cfsa-pmw.warwick.ac.uk/mediawiki/index.php/EPOCH:FAQ) is a code for plasma physics simulations using the Particle-in-Cell method. The simulation results are written is `.sdf` binary files. Several readers for this files are available at https://cfsa-pmw.warwick.ac.uk/SDF. This package intends to be another reader for the `.sdf` file type.

## Quick start

Install the package using
```
]add SDFReader
```

Assuming that you have a folder with `.sdf` files generated from
an EPOCH simulation, use `read_simulation` to read the metadata
for the simulation. You can index into the resulting object and access
individual simulation files. Note that by default EPOCH starts indexing
form 0, while in Julia we usually start from 1.

```julia
using SDFReader

dir = "my_simulation"
sim = read_simulation(dir)
sim[1] # corresponds to the first sdf file (usually 0000.sdf).
```

With the `keys` function you can observe what data was saved in the
simulation. The symbols correspond to the names used for the
saved variables. Note that some identifiers used by EPOCH, such
as the ones for species properties are not valid julia symbols
(such as `px/electron`), so they must be written like `Symbol("px/electron")`.

```julia
keys(sim[1])
```

In order to read the data for scalar field quantities such as `:ex` or `Symbol("px/electron")`,
you can simply index into the file

```julia
file = sim[1]
Ex = file[:ex]
```
The returned object will have a `.data` and `.grid` fields which will contain
arrays that store the values (with units
via [Unitful.jl](https://github.com/PainterQubits/Unitful.jl/)) and the corresponding coordinate
values.

If you need more direct acces to the data, you can use the `read` function
as follows
```julia
w = read(file, Symbol("weight/electron"))
Ex, Ey = read(file, :ex, :ey)
```
Note that in this case the corresponding grids for the fields (e.g. `:ex` and `:ey` in the above)
are not automatically created. Thus this way of acessing the data is recommended only
in more advanced cases.

You can also acces the (simulation) time corresponding to a file with
```julia
get_time(file)
```
and also the parameters from the `input.deck` file with `get_parameter`.
The `input.deck` parser only supports simple `key=value` expressions.
You can also access nested values by providing a second argument.
```julia
nx = get_parameter(file, :nx)
λ = get_parameter(file, :laser, :lambda)
```

For more information regarding the information contained in the `.sdf` files,
please consult the following
* [EPOCH documentation](https://cfsa-pmw.warwick.ac.uk/mediawiki/index.php/EPOCH:Landing_Page)
* [SDF file format documentation](https://cfsa-pmw.warwick.ac.uk/SDF/SDF_documentation)
