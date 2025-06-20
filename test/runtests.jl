using Test, DSP
using GastonRecipes: PlotRecipe, AxisRecipe, FigureRecipe
using GastonDSP: convert_args

@testset "Spectrogram" begin
    fs = 1000 # sampling frequency in Hz
    t1 = 5    # some time in seconds
    f0 = 50  # initial frequency
    f1 = 450  # frequency in Hz at t1
    D = 5 # time duration
    t = range(0, D, step = 1/fs) # time
    # quadratic chirp
    β = (f1 - f0)/(t1^2)
    f(t) = f0 + β*t^2    # instantaneous frequency
    # phase - integral of f(t)
    ϕ = [0.0]
    for i in 1:length(t)-1
        push!(ϕ, ϕ[end] + f(t[i])/fs)
    end
    s = cos.(2π*ϕ)    # chirp signal
    ov = 100          # overlap
    win = hanning(ov) # window
    sp = spectrogram(s, ov, 80, fs = fs, window = win)    # spectrogram
    f1 = convert_args(sp)
    @test f1 isa AxisRecipe
end

@testset "FilterCoefficients" begin
    fs = 100
    responsetype = Bandpass(15, 30)
    designmethod = Butterworth(11)
    flt = digitalfilter(responsetype, designmethod; fs=fs)
    fig = convert_args(flt)
    @test fig isa FigureRecipe
end
