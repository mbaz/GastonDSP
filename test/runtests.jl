using Test, DSP
using GastonRecipes: PlotRecipe, AxisRecipe, FigureRecipe
using GastonDSP: convert_args, CircStem

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
    fig = convert_args(flt, type = :mag)
    @test fig isa AxisRecipe
    fig = convert_args(flt, type = :phase)
    @test fig isa AxisRecipe
    fig = convert_args(flt, type = :zp)
    @test fig isa AxisRecipe
    fig = convert_args(flt, type = :grpdelay)
    @test fig isa AxisRecipe
    fig = convert_args(flt, type = :stepresp)
    @test fig isa AxisRecipe
    fig = convert_args(flt, type = :impresp)
    @test fig isa AxisRecipe
    fig = convert_args(flt, type = :all)
    @test fig isa FigureRecipe
    fig = convert_args(flt, type = (:mag, :zp))
    @test fig isa FigureRecipe
    fig = convert_args(flt, type = (:grpdelay, :mag, :impresp))
    @test fig isa FigureRecipe
end

@testset "CircStem" begin
    n = 1 .+ sin.(2π.*range(0,1-1/32,length=32) .- π/4)
    fig = convert_args(CircStem, n)
    @test fig isa AxisRecipe
end

