function get_units(unit_str)
    isempty(unit_str) && return 1
    # workaround for number density units
    unit_str == "#" && return 1
    # workaround stuff like kg.m/s
    unit_str = replace(unit_str, "."=>"*")
    # workaround stuff like 1/m^3
    if occursin(r"1\/([a-z]*\^[0-9]?)", unit_str)
        unit_str = replace(unit_str, r"1\/([a-z]*)\^([0-9]?)" => s"\g<1>^-\g<2>")
    end
    uparse(unit_str)
end

get_units(unit_str::NTuple) = get_units.(unit_str)
