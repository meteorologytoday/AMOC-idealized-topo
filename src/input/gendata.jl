using ArgParse
using DataStructures
using JSON
using Statistics

s = ArgParseSettings()
@add_arg_table s begin

    "--output-dir"
        help = "Output directory."
        arg_type = String
        default = "input_binary_data"

    "--emp-north-boundary"
        help = "The evaporation-minus-evaporation (emp) value at the northern boundary. Unit: m/s"
        arg_type = Float64
        required = true

end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))

JSON.print(parsed, 4)
function writeBinary(
    filename :: String,
    a :: AbstractArray{T},
) where T

    s = sizeof(Float32)
    a_hton = hton.(convert(Array{Float32}, a))

    open(filename, "w") do io
        nb = write(io, a_hton)
        expect_nb = s * length(a_hton)
        if nb != s*length(a_hton)
            throw(ErrorException("Error: I expect $expect_nb bytes got written but only $nb bytes are."))
        end
        println("File written: $filename ($nb bytes)")
    end

end

Re = 6371e3  # Radius of earth (m)
Ho = 4500.0  # depth of ocean (m)
nλ = 32    # gridpoints in λ
nϕ = 32    # gridpoints in ϕ
λo = 0.0   # origin in λ,ϕ for ocean domain in degrees
ϕo = 10.0  # (i.e. southwestern corner of ocean domain)
Δλ = 2.0   # grid spacing in λ (degrees longitude)
Δϕ = 2.0   # grid spacing in ϕ (degrees latitude)
λeast  = λo + (nλ-2) * Δλ   # eastern extent of ocean domain
ϕnorth = ϕo + (nϕ-2) * Δϕ   # northern extent of ocean domain

λ = reshape(collect(Float64, range(λo - Δλ/2.0, λeast  + Δλ/2.0, length=nλ)), :, 1)
ϕ = reshape(collect(Float64, range(ϕo - Δϕ/2.0, ϕnorth + Δϕ/2.0, length=nϕ)), 1, :)

println("ϕ = ", ϕ)
println("λ = ", λ)

λ_sT = repeat(λ, outer = ( 1, nϕ))
ϕ_sT = repeat(ϕ, outer = (nλ,  1))

Δx_sT = Re * cos.(deg2rad.(ϕ_sT)) * deg2rad(Δλ)
Δy_sT = Re * deg2rad(Δϕ)
Δσ_sT = Δx_sT .* Δy_sT


# Mask. 1 = ocean, 0 = land
mask_sT = ones(Float64, nλ, nϕ)
mask_sT[:, [1, nϕ]] .= 0.0   # set ocean depth to zero at north and south walls
mask_sT[[1, nλ], :] .= 0.0   # set ocean depth to zero at east and west walls

# Flat bottom at z=-Ho
h_sT = - Ho * ones(Float64, nλ, nϕ) .* mask_sT


# Zonal wind-stress
taux = λ_sT * 0.0
tauy = λ_sT * 0.0

# Restoring temperature (function of ϕ only)
g0 = 9.81
α  = 2.0e-4
β  = 7.4e-4
ΔT = 30.0

SST = 0.0 .+ ΔT / 2.0 * ( 1.0 .+ cos.( π * (ϕ_sT .- ϕo) / (ϕnorth - ϕo) ) ) 
SSS = SST * 0.0 .+ 35.0

# Construct EmPmR (Evaporation minus precipitation)
EmPmR = - cos.( π * (ϕ_sT .- ϕo) / (ϕnorth - ϕo) ) .* mask_sT

area_weighted_mean = (arr,) -> sum(arr .* Δσ_sT .* mask_sT) / sum(Δσ_sT .* mask_sT)
println("Before the mean = ", area_weighted_mean(EmPmR))
println("mean = ", mean(EmPmR))
EmPmR[mask_sT .== 1] .-= area_weighted_mean(EmPmR)   # require mean to be zero
EmPmR .*= parsed["emp-north-boundary"] / EmPmR[2, end-1]
println("After the mean = ", area_weighted_mean(EmPmR))


idx = EmPmR .< 0
total_water_flux = - sum(EmPmR[idx] .* Δσ_sT[idx] .* mask_sT[idx]) * 1e-6 # 1 Sv = 1e6 m^3 / s


println("Outputting files...")
mkpath(parsed["output-dir"])
writeBinary(joinpath(parsed["output-dir"], "area.bin"), Δσ_sT)
writeBinary(joinpath(parsed["output-dir"], "bathy.bin"), h_sT)
#writeBinary(joinpath(parsed["output-dir"], "taux.bin"), taux)
#writeBinary(joinpath(parsed["output-dir"], "tauy.bin"), tauy)
writeBinary(joinpath(parsed["output-dir"], "SST.bin"), SST)
writeBinary(joinpath(parsed["output-dir"], "SSS.bin"), SSS)
writeBinary(joinpath(parsed["output-dir"], "EmPmR.bin"), EmPmR)

println("Total water flux = $total_water_flux Sv")

