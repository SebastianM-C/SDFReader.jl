function process_value(::Val{:control}, key, val, global_p, current_p)
    control_block_global_parameters = (
        r"n[x,y,z]",
        "nparticles",
        "nsteps",
        "t_end",
        r"[x,y,z]_(min|max|end)",
    )

    process_value(key,
        val,
        global_p,
        current_p,
        control_block_global_parameters)
end
