include("constant.jl")

using NCDatasets
using Formatting
using ArgParse
using DataStructures
using JSON
using Statistics

s = ArgParseSettings()
@add_arg_table s begin

    "--data-file"
        help = "Output directory."
        arg_type = String
        required = true

    "--grid-file"
        help = "Output directory."
        arg_type = String
        required = true
 
    "--output-file"
        help = "Output directory."
        arg_type = String
        required = true

end

parsed = DataStructures.OrderedDict(parse_args(ARGS, s))
JSON.print(parsed, 4)


Dataset(parsed["grid-file"]) do ds
    global z_w = ds["RF"][:]
    global dx_V = ds["dxG"][:] # (Yp1,X)
    global dz_V = ds["drF"][:] # (Z,)
    global dAy_V = reshape(dx_V, size(dx_V)..., 1) .* reshape(dz_V, 1, 1, size(dz_V)...)
end



Dataset(parsed["data-file"]) do ds
    global VVEL  = nomissing(ds["VVEL"][:, :, :, :], NaN) 
    global THETA = nomissing(ds["THETA"][:, :, :, :], NaN) 
    global SALT  = nomissing(ds["SALT"][:, :, :, :], NaN) 
end

println(size(VVEL))

Nx, Nyp1, Nz, Nt = size(VVEL)
Ny = Nyp1 - 1
Nzp1 = Nz + 1

ψ = zeros(Float64, Nyp1, Nzp1, Nt)
println("Compute streamfunction... ")
for t=1:Nt
    # compute total meridional volume flux
    local vol_flux = sum(dAy_V .* view(VVEL, :, :, :, t), dims=1)[1, :, :]

    for j=1:Nyp1
        for k=1:Nz
            ψ[j, k+1, t] = ψ[j, k, t] + vol_flux[j, k]
        end
    end
end

println("Compute buoyancy")
BUOY = α * THETA + β * SALT

Dataset(parsed["output-file"], "c") do ds

    defDim(ds, "time", Inf)
    defDim(ds, "Yp1", Nyp1)
    defDim(ds, "Zp1", Nzp1)

    for (varname, vardata, vardim, attrib) in [
        ("psi", ψ, ("Yp1", "Zp1", "time",), Dict()),
    ]
        println("Doing varname:", varname)
        var = defVar(ds, varname, Float64, vardim)
        var.attrib["_FillValue"] = 1e20

        for (k, v) in attrib
            var.attrib[k] = v
        end

        rng = []
        for i in 1:length(vardim)-1
            push!(rng, Colon())
        end
        push!(rng, 1:size(vardata)[end])
        var[rng...] = vardata

    end

end

