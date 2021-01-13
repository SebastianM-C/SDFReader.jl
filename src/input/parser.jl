include("constant.jl")
include("control.jl")
include("no_globals.jl")
include("no_parsing.jl")
include("output.jl")

function parse_input(file)
    inside_block = false
    block_type = Symbol()
    global_p = NamedTuple()
    current_p = NamedTuple()
    prev_line = ""

    for line in eachline(file)
        l = strip(line)
        @debug "Parsing line $l"
        startswith(l, '#') || isempty(l) && continue

        if !inside_block
            directive = strip.(split(l, ':'))
            @assert length(directive) == 2 "Unknown input directive $directive on line $line"

            if directive[1] == "begin"
                inside_block = true
                block_type = Symbol(directive[2])
            elseif directive[1] == "import"
                parse_input(directive[2])
            else
                @error "Unknown input command $(directive[1])"
            end
        else
            if startswith(l, "end")
                ending = strip(split(l, ':')[2])
                @assert ending == string(block_type) "Invalid block ending on line $l expected $block_type got $ending"
                inside_block = false
                # handle repeted blocks with same type
                if block_type == :species
                    block_name = Symbol(string(block_type) * "_" * current_p.name)
                    global_p = push!!(global_p, block_name=>current_p)
                else
                    global_p = push!!(global_p, block_type=>current_p)
                end
                current_p = NamedTuple()
                block_type = Symbol()
                continue
            end
            # trim comments
            ln = strip(split(l, '#')[1])
            isempty(ln) && continue

            if endswith(ln, "\\")
                prev_line = ln
                continue
            end
            if !isempty(prev_line)
                ln *= prev_line
                prev_line = ""
            end

            @debug "Splitting line $ln"
            if occursin('=', ln)
                key, value = split(ln, '=')
            elseif occursin(':', ln)
                key, value = split(ln, ':')
            else
                @error "Unable to split key value pair on line $ln"
            end
            key = strip(key)
            value = strip(value)

            # replace constants
            for (i, j) in input_deck_constants
                value = replace(value, i=>j)
            end
            @debug "Got key-value pair: $key = $value"
            global_p, current_p = process_value(
                Val(block_type),
                key,
                value,
                global_p, current_p)
        end
    end

    all_species = ()
    @debug "Adding species list"
    for k in keys(global_p)
        str = string(k)
        if startswith(str, "species")
            push!!(all_species, split(str, '_', limit=2)[2])
        end
    end
    push!!(global_p, :species=>all_species)

    return global_p
end

function process_value(key, val, global_p, current_p, block_parameters)
    k = Symbol(key)
    v = parse_value(k, val, merge!!(global_p, current_p))
    current_p = push!!(current_p, k=>v)
    if is_global(key, block_parameters)
        global_p = push!!(global_p, k=>v)
    end
    return global_p, current_p
end

function is_global(key, block_p)
    any(occursin.(block_p, (key,)))
end

function parse_value(k, v, existing_params)
    str = replace_existing_params(v, existing_params)
    @debug "Trying to parse units in $str"
    val = try
        uparse(str)
    catch err
        @debug "Could not parse $str. Error: $err"
        str
    end
    @debug "Tried to parse $k with unitful and got $val"
    # try to auto-add units
    if !isa(val, String) && k in keys(input_unitful_entries) && unit(val) == NoUnits
        val *= input_unitful_entries[k]
        @debug "Added unit: $val"
    end

    if val isa String
        @debug "Could not fully parse $val."
        v
    else
        @debug "Successfully parsed $val."
        val
    end
end

function replace_existing_params(str, existing_params)
    # simple replacements with previously defined keys
    @debug "Looking for known values in $str"
    new_str = deepcopy(str)
    for m in eachmatch(r"\w+\d?", str)
        val = m.match
        if val in string.(keys(existing_params))
            known_val = getproperty(existing_params, Symbol(val))
            if known_val isa String
                continue
            end
            @debug "Replacing $val with $known_val"
            # Workaround https://github.com/PainterQubits/Unitful.jl/issues/391
            if unit(known_val) ≠ NoUnits
                new_val = string(ustrip(known_val))
            else
                new_val = string(known_val)
            end
            new_str = replace(new_str, val=>"($new_val)")
            @debug "Updated string with new value: $new_str"
        end
    end
    new_str
end

const input_deck_constants = Dict(
    "T" => "true",
    "F" => "false",
    "qe" => "q",
    "epsilon0" => "ϵ0",
    "mu0" => "μ0",
    "ev" => "eV",
    "kev" => "keV",
    "mev" => "MeV",
    "micron" => "μm",
    "milli" => "1e-3",
    "micro" => "1e-6",
    "nano" => "1e-9",
    "pico" => "1e-12",
    "femto" => "1e-15",
    "atto" => "1e-18",
    "cc" => "1e-6",
)

const input_unitful_entries = Dict(
    :t_end => u"s",
    :x_min => u"m",
    :y_min => u"m",
    :z_min => u"m",
    :x_max => u"m",
    :y_max => u"m",
    :z_max => u"m",
    :charge => u"q",
    :mass => m_e,
    :number_density => u"m^-3",
    :temperature => u"K",
    :amp => u"V/m",
    :intensity_w_cm2 => u"W/cm^2",
    :omega => u"rad/s",
    :frequency => u"Hz",
    :lambda => u"m",
    :polarisation_angle => u"rad",
    :pol_angle => u"rad",
    :polarisation => u"°",
    :pol => u"°",
    :phase => u"rad",
    :t_start => u"s",
    :t_end => u"s",
    :dt_snapshot => u"s",
)
