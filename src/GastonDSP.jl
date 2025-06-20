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
    convert_args(fc::DSP.FilterCoefficients{:z})

Recipe to plot a DSP.FilterCoefficients object.
"""
function convert_args(f::F) where F <: FilterCoefficients
    if f isa FilterCoefficients{:z}
        un = "'Normalized frequency (radians/sample)'"
    else
        un = "'Normalized frequency (radians/second)'"
    end
    H, w = freqresp(f)
    p1 = PlotRecipe((w, abs.(H)))
    p2 = PlotRecipe((w, angle.(H)))
    a1 = AxisRecipe("set grid\nset title '|H|'\nset xlabel $un", [p1])
    a2 = AxisRecipe("set grid\nset title '∠ H'\nset xlabel $un", [p2])
    FigureRecipe([a1, a2], "layout 2,1", false)
end

end # module GastonDSP
