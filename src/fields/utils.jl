LinearAlgebra.norm(field::VectorField) = ScalarField(norm.(field.data), field.grid)
