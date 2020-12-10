function process_value(::Val{:constant}, key, val, global_p, current_p)
    k = Symbol(key)
    val = parse_value(k, val, merge!!(global_p, current_p))
    current_p = push!!(current_p, k=>val)
    global_p = push!!(global_p, k=>val)

    return global_p, current_p
end
