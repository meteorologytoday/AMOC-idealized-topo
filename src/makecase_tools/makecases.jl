using TOML
using ArgParse
using JSON
using DataStructures
using NCDatasets
using Formatting

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

println("""
This program makes directories that contains forcing files.
""")
s = ArgParseSettings()
@add_arg_table s begin

    "--label"
        help = "Everything will be contained in this directory"
        arg_type = String
        required = true

    "--p-vec"
        help = "p vec"
        arg_type = Float64
        nargs = '+'
        required = true


end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)

p_vec = parsed["p-vec"]
#collect(Float64, range(0.0, -10e-7, length=11))  # unit: m/s

if isdir(parsed["label"])
    throw(ErrorException("`$(parsed["label"])` exists."))
end

mkpath(parsed["label"])
cd(parsed["label"])

for (i, p) in enumerate(p_vec)
    
    casename = format("case_{:02d}", i) 
    mkpath(casename)
    
    pleaseRun(`julia $(@__DIR__)/gendata.jl
        --output-dir $(casename)
        --empmr-north-boundary $p
    `)
    
    caseinfo = Dict(
        "empmr" => p,
    )
        
    open("$(casename)/caseinfo.toml", "w") do io
        TOML.print(io, caseinfo; sorted=true)
    end
end

