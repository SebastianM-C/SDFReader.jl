function process_value(::Val{:output}, key, val, global_p, current_p)
    if key == "dt_snapshot"
        process_value(key,
        val,
        global_p,
        current_p,
        ("dt_snapshot",))
    else
        k = Symbol(key)
        current_p = push!!(current_p, k=>val)
        global_p, current_p
    end
end
