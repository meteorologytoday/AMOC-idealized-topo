using ArgParse
using DataStructures
using JSON
using Statistics
using Formatting

s = ArgParseSettings()
@add_arg_table s begin

    "--pickup-src-dir"
        help = "Directory that contains pickup files."
        arg_type = String
        required = true
 
    "--pickup-dst-dir"
        help = "Target directory."
        arg_type = String
        required = true
    
    "--pickup-year"
        help = "Pickup year"
        arg_type = Int64
        required = true

    "--deltaT"
        help = "deltaT that is used to time step the model. This is used to compute the iteration number."
        arg_type = Int64
        required = true
end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)


function runOneCmd(cmd)
    println(">> ", string(cmd))
    run(cmd)
end

function pleaseRun(cmd)
    if isa(cmd, Array)
        for i = 1:length(cmd)
            runOneCmd(cmd[i])
        end
    else
        runOneCmd(cmd)
    end
end

p_vec = collect(Float64, range(0.0, -10e-7, length=11))

p_vec_str = join(p_vec, " ")

niter = format("{:010d}", parsed["pickup-year"] * 360 * 86400 / parsed["deltaT"])

pleaseRun(`bash -c "cp $(parsed["pickup-src-dir"])/pickup.$(niter).* $(parsed["pickup-dst-dir"])"`)
