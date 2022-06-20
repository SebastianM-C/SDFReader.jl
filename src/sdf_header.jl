struct Header
    sdf_magic::String
    endianness::Int32
    file_version::Int32
    file_revision::Int32
    code_name::String
    first_block_location::Int64
    summary_location::Int64
    summary_size::Int32
    nblocks::Int32
    block_header_length::Int32
    step::Int32
    time::Float64
    jobid1::Int32
    jobid2::Int32
    string_length::Int32
    code_io_version::Int32
end

# T Data type
# N Dimensionality of data
# B Dispatch puropeses (in read for choosing block type)
struct BlockHeader{T,N,B}
    next_block_location::Int64
    data_location::Int64
    id::String
    data_length::Int64
    name::String
end

function BlockHeader(f::IOStream, start, string_length, header_length)
    seek(f, start)
    next_block_location = read(f, Int64)
    data_location = read(f, Int64)
    id = simple_str(read(f, ID_LENGTH))
    data_length = read(f, Int64)
    block_type = read(f, Int32)
    data_type = read(f, Int32)
    n_dims = read(f, Int32)
    name = simple_str(read(f, string_length))

    d_type = typemap(Val(data_type))
    seek(f, start + header_length)

    BlockHeader{d_type,Int(n_dims),block_type}(
        next_block_location,
        data_location,
        id,
        data_length,
        name,
    )
end

abstract type AbstractBlockHeader{T,N} end

Base.ndims(::AbstractBlockHeader{T,N}) where {T,N} = N
Base.eltype(::AbstractBlockHeader{T}) where {T} = T
Base.nameof(block::BlockHeader) = block.name

struct ConstantBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T,N}
    val::T
end

struct CPUSplitBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T,N}
end

@enum Geometry begin
    Null = 0
    Cartesian = 1
    Cylindrical = 2
    Spherical = 3
end

@doc """
    PlainMeshBlockHeader{T,N}

A mesh defines the locations at which variables are defined.
Since the geometry of a problem is fixed and most variables will be defined
at positions relative to a fixed grid, it makes sense to write this
position data once in its own block.
Each variable will then refer to one of these mesh blocks to provide their location data.

The `PlainMeshBlockHeader` is used for representing the positions at which
scalar field discretizations are defined.
The block header contains the `base_header` (a `BlockHeader`) and the following metadata
- `mults`: The normalisation factor applied to the grid data
in each direction.
- `labels`: The axis labels for this grid in each direction.
- `units`: The units for this grid in each direction after the
normalisation factors have been applied.
- `geometry`: The geometry of the block.
- `minval`: The minimum coordinate values in each direction.
- `maxval`: The maximum coordinate values in each direction.

The geometry of the block can take the following values
- `Null`: Unspecified geometry. This is an error.
- `Cartesian`: Cartesian geometry.
- `Cylindrical`: Cylindrical geometry.
- `Spherical`: Spherical geometry.

The last item in the header is `dims`, is the number of grid points in
each dimension.

The data written is the locations of node points for the mesh in each
of the simulation dimensions.
Therefore for a 3d simulation of resolution ``(nx; ny; nz)``, the data will consist of
a 1d array of X positions with ``(nx + 1)`` elements followed by
a 1d array of Y positions with ``(ny + 1)`` elements and finally
a 1d array of Z positions with ``(nz + 1)`` elements.
Here the resolution specifies the number of simulation cells and therefore
the nodal values have one extra element. In a 1d or 2d simulation, you would
write only the X or X and Y arrays respectively.
"""
struct PlainMeshBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T}

    mults::NTuple{N,Float64}
    labels::NTuple{N,String}
    units::NTuple{N,String}
    geometry::Geometry
    minval::Array{Float64,1}
    maxval::Array{Float64,1}
    dims::Array{Int32,1}
end

function Base.size(block::PlainMeshBlockHeader{T,N}) where {T,N}
    ntuple(Val(N)) do i
        block.dims[i]
    end
end

Base.size(block::PlainMeshBlockHeader, i::Int) = block.dims[i]

@doc """
    PointMeshBlockHeader{T,N}

A mesh defines the locations at which variables are defined.
Since the geometry of a problem is fixed and most variables will be defined
at positions relative to a fixed grid, it makes sense to write this
position data once in its own block.
Each variable will then refer to one of these mesh blocks to provide their location data.

The `PointMeshBlockHeader` is used for representing the positions at which
vector field discretizations are defined.
The block header contains the `base_header` (a `BlockHeader`) and the following metadata
- `mults`: The normalisation factor applied to the grid data
in each direction.
- `labels`: The axis labels for this grid in each direction.
- `units`: The units for this grid in each direction after the
normalisation factors have been applied.
- `geometry`: The geometry of the block.
- `minval`: The minimum coordinate values in each direction.
- `maxval`: The maximum coordinate values in each direction.
- `np`: The number of points.

The geometry of the block can take the following values
- `Null`: Unspecified geometry. This is an error.
- `Cartesian`: Cartesian geometry.
- `Cylindrical`: Cylindrical geometry.
- `Spherical`: Spherical geometry.

The data written is the locations of each point in the first direction followed by
the locations in the second direction and so on.
Thus, for a 3d simulation, if we define the first point as having coordinates
``(x_1; y_1; x_1)`` and the second point as ``(x_2; y_2; z_2)``, etc.
then the data written to file is a 1d array with
 elements ``(x_1; x_2; \\dots; x_{np})``, followed by
the array ``(y_1; y_2; \\dots; y_{np})`` and finally
the array ``(z_1; z_2; \\dots; z_{np})`` where ``np`` corresponds to the
number of points in the mesh. For a 1d simulation, only the x array is written
and for a 2d simulation only the x and y arrays are written.
"""
struct PointMeshBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T,N}

    mults::NTuple{N,Float64}
    labels::NTuple{N,String}
    units::NTuple{N,String}
    geometry::Geometry
    minval::Array{Float64,1}
    maxval::Array{Float64,1}
    np::Int64
end

Base.size(block::PointMeshBlockHeader{T,D}) where {T,D} = ntuple(_ -> block.np, Val(D))
Base.size(block::PointMeshBlockHeader, ::Int) = block.np

@enum Stagger begin
    CellCentre = 0
    FaceX = 1
    FaceY = 2
    FaceZ = 4
    EdgeX = 6
    EdgeY = 5
    EdgeZ = 3
    Vertex = 7
end

@doc """
    PlainVariableBlockHeader{T,N}

The `PlainVariableBlockHeader` is used to describe a variable which is
located relative to the points given in a mesh block.

The block header contains the `base_header` (a `BlockHeader`) and the following metadata
- `mult`: The normalisation factor applied to the variable data.
- `units`: The units for this variable after the normalisation factor has
been applied.
- `mesh_id`: The name(`id`) of the mesh relative to which this block's data is defined.
- `dims`: The number of grid points in each dimension.
- `stagger`: The location of the variable relative to its associated mesh.

The mesh associated with a variable is always node-centred, i.e. the values written as
mesh data specify the nodal values of a grid. Variables may be defined at points
which are offset from this grid due to grid staggering in the code.
The `stagger` entry specifies where the variable is defined relative to the mesh.
Since we have already defined the number of points that the associated mesh contains,
this determines how many points are required to display the variable.

The `stagger` entry can take one of the following values
- `CellCentre`: Cell centred. At the midpoint between nodes. Implies an
``(nx; ny; nz)`` grid.
- `FaceX`: Face centred in X. Located at the midpoint between nodes on
the Y-Z plane. Implies an ``(nx + 1; ny; nz)`` grid.
- `FaceY`: Face centred in Y. Located at the midpoint between nodes on
the X-Z plane. Implies an ``(nx; ny + 1; nz)`` grid.
- `FaceZ`: Face centred in Z. Located at the midpoint between nodes on
the X-Y plane. Implies an ``(nx; ny; nz + 1)`` grid.
- `EdgeX`: Edge centred along X. Located at the midpoint between nodes
along the X-axis. Implies an ``(nx; ny + 1; nz + 1)`` grid.
- `EdgeY`: Edge centred along Y. Located at the midpoint between nodes
along the Y-axis. Implies an ``(nx + 1; ny; nz + 1)`` grid.
- `EdgeZ`: Edge centred along Z. Located at the midpoint between nodes
along the Z-axis. Implies an ``(nx + 1; ny + 1; nz)`` grid.
- `Vertex`: Node centred. At the same place as the mesh. Implies an ``(nx+
1; ny + 1; nz + 1)`` grid.

For a grid based variable, the data written contains the values of
the given variable at each point on the mesh.
This is in the form of a 1d, 2d or 3d array depending on the dimensions
of the simulation. The size of the array depends on the size of
the associated mesh and the grid staggering as indicated above. It
corresponds to the values written into the `dims` array written for
this block.
"""
struct PlainVariableBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T,N}

    mult::Float64
    units::String
    mesh_id::String
    dims::NTuple{N,Int32}
    stagger::Stagger
end

Base.size(block::PlainVariableBlockHeader) = block.dims
Base.size(block::PlainVariableBlockHeader, i::Int) = block.dims[i]

@doc """
    PointVariableBlockHeader{T,N}

The `PointVariableBlockHeader` is used to describe a variable which is
located relative to the points given in a mesh block.

The block header contains the `base_header` (a `BlockHeader`) and the following metadata
- `mult`: The normalisation factor applied to the variable data.
- `units`: The units for this variable after the normalisation factor has
been applied.
- `mesh_id`: The name(`id`) of the mesh relative to which this block's data is defined.
- `np`: The number of points.

Similarly to the grid based variable, the data written contains the values
of the given variable at each point on the mesh. Since each the location of
each point in space is known fully, there is no need for a stagger variable.
The data is in the form of a 1d array with `np` elements.
"""
struct PointVariableBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T,N}

    mult::Float64
    units::String
    mesh_id::String
    np::Int64
end

Base.size(block::PointVariableBlockHeader) = (block.np,)

struct RunInfoBlockHeader{T,N} <: AbstractBlockHeader{T,N}
    base_header::BlockHeader{T,N}
end
