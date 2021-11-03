using ArgParse
using DataStructures
using JSON
using Statistics
using Formatting

s = ArgParseSettings()
@add_arg_table s begin

    "--nml"
        help = "Namelist file."
        arg_type = String
        required = true

    "--beg-year"
        help = "Begin year."
        arg_type = Int64
        required = true

    "--end-year"
        help = "End year."
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


sec_per_year = 360 * 86400

if parsed["end-year"] <= parsed["beg-year"]
    throw(ErrorException("Begin year should not be larger than end year."))
end

start_time_str = format("{:d}", sec_per_year * parsed["beg-year"])
end_time_str = format("{:d}", sec_per_year * parsed["end-year"])

pleaseRun(`python3 $(@__DIR__)/chnml.py --file $(parsed["nml"]) --grp PARM03 --key startTime --val $(start_time_str) --verbose --sort`)
pleaseRun(`python3 $(@__DIR__)/chnml.py --file $(parsed["nml"]) --grp PARM03 --key endTime --val $(end_time_str) --verbose --sort`)
