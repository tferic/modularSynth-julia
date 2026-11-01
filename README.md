# modularSynth-julia

This is an experimental proof-of-work script to see how audio notes can be played (generated) on Linux.  

P.S. If you just want to make music through computer code, try Strudel.  

## Configuring Audio

The script will read the audio configuration from a file `audio_config.toml` from the same directory where the script is ran.  
The script will use "pulse" (for "Pulse Audio") as the audio device.  
If that doesn't work, it is best to see the list of Audio devices from within a Julia REPL, and remember the device name of the correct audio output device.  
```julia
using PortAudio
PortAudio.devices()
```

See module documentation [here](https://github.com/JuliaAudio/PortAudio.jl)
