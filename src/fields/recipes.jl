AbstractPlotting.convert_arguments(P::Type{<:Volume}, f::ScalarField) = convert_arguments(P, f.grid..., f.data)
AbstractPlotting.convert_arguments(P::Type{<:Contour}, f::ScalarField) = convert_arguments(P, f.grid..., f.data)
AbstractPlotting.convert_arguments(P::Type{<:Scatter}, f::ScalarVariable) = convert_arguments(P, f.grid...)
