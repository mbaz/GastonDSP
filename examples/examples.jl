using Gaston, GastonDSP, DSP

# spectrogram
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
fig = @plot {palette = :inferno} "set title 'Spectrogram'" sp
save(fig, filename = "spectrogram.png", term = "pngcairo font ',10' size 640,480")

# FilterCoefficients
fs = 100
responsetype = Bandpass(15, 30)
designmethod = Butterworth(11)
flt = digitalfilter(responsetype, designmethod; fs=fs)

# magnitude and phase
fig = plot(flt, fs = fs)
save(fig, filename = "filter-magphase.png", term = "pngcairo font ',10' size 640,480")

# zero-pole
fig = plot(flt, type = :zp, fs = fs)
save(fig, filename = "filter-zeropole.png", term = "pngcairo font ',10' size 640,480")

# group delay, impulse and step responses
fig = plot(flt, type = (:grpdelay, :stepresp, :impresp), fs = fs)
save(fig, filename = "filter-delayresps.png", term = "pngcairo font ',10' size 640,480")

# exploring filter orders
orders = [3, 5, 7, 9, 11]
fig = plot(digitalfilter.((Bandpass(15, 30),), Butterworth.(orders), fs = fs)..., type = (:mag, :impresp), fs = fs, keys = orders)
save(fig, filename = "filter-orders.png", term = "pngcairo font ',10' size 640,480")

# circular-axis stem
n = 1 .+ sin.(2π.*range(0,1-1/32,length=32) .- π/4)
fig = plot(GastonDSP.CircStem, n)
save(fig, filename = "circstem.png", term = "pngcairo font ',10' size 640,480")
