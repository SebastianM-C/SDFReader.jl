function no_processing(key, val, global_p, current_p)
    k = Symbol(key)
    current_p = push!!(current_p, k=>val)
    global_p, current_p
end

process_value(::Val{:boundaries}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:fields}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:particles_from_file}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:dist_fn}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:probe}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:collisions}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:qed}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:bremsstrahlung}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:injector}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)

process_value(::Val{:subset}, key, val, global_p, current_p) =
    no_processing(key, val, global_p, current_p)
