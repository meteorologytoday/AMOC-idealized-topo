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

#=
p_vec = collect(Float64, range(0.0, -4.0e-7, length=21))
p_vec_str = join(p_vec, " ")
pleaseRun(`bash -c "julia tools/makecases.jl --label testt --p-vec $p_vec_str"`)
=#

p0 = 0.0
dp = -0.2e-8
p_vec = [p0 + dp*(i-1) for i=1:201]
p_vec_str = join(p_vec, " ")

#p_vec = collect(Float64, range(0.0, -3.0e-8, length=11))

#pleaseRun(`bash -c "julia tools/makecases.jl --label _scan_pos_batch2 --p-vec $p_vec_str"`)

pleaseRun(`bash -c "julia tools/makecases.jl --label scaffold --p-vec $p_vec_str"`)
