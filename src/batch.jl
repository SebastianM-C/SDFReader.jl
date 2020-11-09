function read2(f, block::PlainVariableBlockHeader{T}; fn=_->true, req_pts, batch_size=(req_pts[end][2]-req_pts[end][1])) where T
    if length(block.npts) != length(req_pts)
        ArgumentError("dimension mismatch")
    end

    block_size = prod(block.npts[1:end-1])
    z1, z2 = req_pts[end]
    seek(f, block.base_header.data_location + sizeof(T)*block_size*(z1-1))
    n, m = divrem(z2-z1, batch_size)
    vals = T[]
    idxs = Array{CartesianIndex{length(req_pts)},1}()
    result = Array{T, 1}(undef, block_size*batch_size)
    for i in eachindex(n)
        read_batch!(f, result, block, fn, req_pts, batch_size, block_size, vals, idxs)
    end
    if m != 0
        result = Array{T, 1}(undef, block_size*m)
        read_batch!(f, result, block, fn, req_pts, m, block_size, vals, idxs)
    end

    for (i,v) in enumerate(req_pts)
        idxs .+= Ref(cart_idx(req_pts[i][1], Val(i)))
    end

    vals, idxs
end

function read_batch!(f, result, block, fn, req_pts, batch_size, block_size, vals, idxs)
    read!(f, result)
    result = trim_block(result, block.npts, batch_size, req_pts, Val(length(req_pts)))
    idx = findall(fn, result)
    append!(vals, result[idx])
    append!(idxs, idx)
end

function trim_block(result, npts, batch_size, req_pts, ::Val{1})
    result
end

function trim_block(result, npts, batch_size, req_pts, ::Val{2})
    x1, x2 = req_pts[1]
    result = reshape(result, (npts[1], batch_size))
    result[x1:x2, :]
end

function trim_block(result, npts, batch_size, req_pts, ::Val{3})
    x1, x2 = req_pts[1]
    y1, y2 = req_pts[2]
    result = reshape(result, (npts[1], npts[2], batch_size))
    result[x1:x2, y1:y2, :]
end

cart_idx(pt, ::Val{1}) = CartesianIndex(pt-1, 0, 0)
cart_idx(pt, ::Val{2}) = CartesianIndex(0, pt-1, 0)
cart_idx(pt, ::Val{3}) = CartesianIndex(0, 0, pt-1)
