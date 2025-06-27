module GastonDSP

using DSP
using GastonRecipes
import GastonRecipes: PlotRecipe, AxisRecipe, FigureRecipe, convert_args

"""
    convert_args(s::Periodograms.Spectrogram; db::Bool = false)

Recipe to plot a DSP.Periodograms.Spectrogram.

Keyword arguments:

* `db`: if `true`, convert the spectrogram power to decibels.
"""
function convert_args(s::Periodograms.Spectrogram; db::Bool = false, clip = [])
    if db
        pow = 10*log10.(power(s))
        if !isempty(clip)
            m = min(pow...)
            M = max(pow...)
            pow[pow .< clip[1]] .= m
            pow[pow .> clip[2]] .= M
        end
        p = PlotRecipe((time(s), freq(s), pow), "w image")
    else
        p = PlotRecipe((time(s), freq(s), power(s)), "w image")
    end
    a = AxisRecipe("""set xlabel 'Time [s]'
                      set ylabel 'Frequency [Hz]'
                   """,
                   [p],
                   false)
end

"""
    convert_args(fc::DSP.FilterCoefficients ;
                 type = (:mag, :phase)
                )

Recipe to plot a DSP.FilterCoefficients object.

The `type` keyword argument selects what to plot:

* `:mag` or `:magnitude`: magnitude of filter response
* `:phase`: phase of filter response
* `:zp` or `zeropole`: zero-pole plot
* `:grp` or `:grpdelay`: group delay
* `:imp` or `:impresp`: impulse response
* `:step` or `:stepresp`: step response

Use `type = :all` to select all options.

The default value of `type` is `(:mag, :phase)`.

A single plot may be specified (`type = :plottype`), or multiple
plots may be specified as a tuple (`type = (:plottype1, :plottype2)`).
In this last case, the plots are displayed in the order given in
the tuple.
"""
function convert_args(filters::FilterCoefficients{:z}... ;
                      fs = 2.0,
                      type = (:mag, :phase),
                      impn = 100, stepn = 100,
                      w = range(0, π, 100),
                      magylim = (-15, Inf),
                      keys = (),
                      lw = 1.5)
    ax = AxisRecipe[]
    if !(type isa Tuple)
        type = (type,)
    end
    if type[1] == :all
        count = 6
    else
        count = length(type)
    end
    freq = fs.*w./(2π)
    for t in type
        if t == :zp || t == :zeropole || t == :all
            fzp = ZeroPoleGain(filters[1])
            p = PlotRecipe[]
            # unit circle
            θ = range(0, 2π, length = 100)
            push!(p, PlotRecipe((cos.(θ), sin.(θ)), "dt '-' lc 'blue'"))
            # poles
            push!(p, PlotRecipe((real.(fzp.p), imag.(fzp.p)), "w p pt 'x' lc 'dark-green' t 'pole'"))
            # zeros
            push!(p, PlotRecipe((real.(fzp.z), imag.(fzp.z)), "w p pt 7 lc 'red' t 'zero'"))
            # axis
            axis = AxisRecipe("set grid
                               set key box outside
                               set xlabel 'Real'
                               set ylabel 'Imaginary'
                               set title 'Zero-Pole plot'", p)
            (count == 1) && return axis
            push!(ax, axis)
        end
        if t == :mag || t == :magnitude || t == :all
        axis = axis_freq(freqresp, amp2db ∘ abs,
                         w, freq, filters, keys, magylim, lw, "|H|", "Magnitude [dB]")
            (count == 1) && return axis
            push!(ax, axis)
        end
        if t == :phase || t == :all
            axis = axis_freq(phaseresp, identity, w, freq, filters, keys, (), lw, "∠ H", "Phase [rad]")
            (count == 1) && return axis
            push!(ax, axis)
        end
        if t == :grp || t == :grpdelay || t == :all
            axis = axis_freq(grpdelay, identity, w, freq, filters, keys, (), lw, "Group Delay", "τ [s]")
            (count == 1) && return axis
            push!(ax, axis)
        end
        if t == :imp || t == :impresp || t == :all
            axis = axis_time(impresp, impn, fs, filters, keys, lw, "Impulse Response")
            (count == 1) && return axis
            push!(ax, axis)
        end
        if t == :step || t == :stepresp || t == :all
            axis = axis_time(stepresp, impn, fs, filters, keys, lw, "Step Response")
            (count == 1) && return axis
            push!(ax, axis)
        end
    end
    FigureRecipe(ax, "layout $count,1", false)
end

function axis_freq(fun, postfun,
                   w, freq, filters, keys, magylim, lw, ptitle, ylabel)::AxisRecipe
    p = PlotRecipe[]
    xl = "'Frequency [Hz]'"
    for (i, filt) in enumerate(filters)
        H = fun(filt, w)
        title = isempty(keys) ? "" : "title '$(keys[i])'"
        title *= " lw $(lw)"
        push!(p, PlotRecipe((freq, postfun.(H)), title))
    end
    if magylim isa Tuple && length(magylim) == 2
        ylim_min = magylim[1] == -Inf ? '*' : magylim[1]
        ylim_max = magylim[2] == Inf ? '*' : magylim[2]
        yrange = "set yrange [$(ylim_min):$(ylim_max)]"
    else
        yrange = "unset yrange"
    end
    if isempty(keys)
        key = "unset key"
    else
        key = "set key box outside title 'Order'"
    end
    AxisRecipe("$yrange
                $key
                set grid
                set title '$ptitle'
                set xlabel $xl
                set ylabel '$ylabel'", p)
end

function axis_time(fun, n, fs, filters, keys, lw, ptitle)::AxisRecipe
            p = PlotRecipe[]
            xl = "'Time [s]'"
            time = range(0, step = 1/fs, length = n)
            for (i, filt) in enumerate(filters)
                ir = fun(filt, n)
                title = isempty(keys) ? "" : "title '$(keys[i])'"
                title *= " lw $(lw)"
                push!(p, PlotRecipe((time, ir), title))
            end
            if isempty(keys)
                key = "unset key"
            else
                key = "set key box outside title 'Order'"
            end
            return AxisRecipe("unset yrange
                               $key
                               set grid
                               set title '$ptitle'
                               set xlabel $xl
                               set ylabel 'Amplitude'", p)
end

struct CircStem end

"""
    convert_args(::Type{CircStem}, samples ; norm = true, view = "70, 30")

Plot a periodic discrete-time sequence over a circular axis, in the
style shown [here:](https://www.dsprelated.com/showarticle/1435.php).
"""
function convert_args(::Type{CircStem}, samples::AbstractVector{<:Real} ;
                      norm = true, view = "70, 30")
    p = PlotRecipe[]
    # plot base circle
    Nc = 100  # number of points in circle
    θc = range(0, 2π - 1/Nc, length = Nc)
    xc = cos.(θc)
    yc = sin.(θc)
    zc = zeros(Nc)
    push!(p, PlotRecipe((xc, yc, zc), "dt '.' lc 'black'"))
    # plot samples
    N = length(samples)
    θ = range(0, 2π - 2π/N, length = N) .+ 16π/10
    x = cos.(θ)
    y = sin.(θ)
    push!(p, PlotRecipe((x, y, samples), "w p lc 'blue' pt 7 ps 0.8"))
    # vertical impulses
    push!(p, PlotRecipe((x, y, samples), "w impulses dt '.' lc 'black'"))
    # arrow
    Na = 20 # points in arrow
    r = 1.7
    θa = range(0, π/5, length = Na) .+ 16π/10
    xa = r.*cos.(θa)
    ya = r.*sin.(θa)
    za = zeros(Na)
    push!(p, PlotRecipe((xa, ya, za), "w l lc 'black' lw 0.75"))
    # axis
    setts = """set arrow from first $(xa[Na-1]),$(ya[Na-1]),0 to first $(xa[Na]),$(ya[Na]),0 size 0.05,20 fixed
               set label 'n' at 1.1, -1.6, 0
               set label '0' at $(x[1]+.075), $(y[1]-0.2), 0
               set label '2' at $(x[3]+.075), $(y[3]-0.2), 0
               set label '4' at $(x[5]+.075), $(y[5]-0.2), 0
               set label '$(N-2)' at $(x[end-1]+.05), $(y[end-1]-0.3), 0
               set view $(view)
               set isotropic
               unset tics
               set border 0
               set xyplane 0
            """
    a = AxisRecipe(setts, p, true)
    return a
end

function convert_args(::Type{CircStem}, x::AbstractVector{<:Complex}, args... ; kwargs)
    r = abs.(x)
    convert_args(CircStem, x, args... ; kwargs...)
end

end # module GastonDSP
