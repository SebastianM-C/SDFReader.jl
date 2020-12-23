function ImageTransformations.imresize(f::T, args...) where T <: AbstractField
    T(imresize(f.data, args...), imresize(f.grid, args...))
end
