process_value(::Val{:stencil}, key, val, global_p, current_p) =
    process_value(key, val, global_p, current_p, ())

process_value(::Val{:laser}, key, val, global_p, current_p) =
    process_value(key, val, global_p, current_p, ())

process_value(::Val{:species}, key, val, global_p, current_p) =
    process_value(key, val, global_p, current_p, ())

process_value(::Val{:window}, key, val, global_p, current_p) =
    process_value(key, val, global_p, current_p, ())
