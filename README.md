# modularSynth-julia

This is an experimental proof-of-work script to see how audio notes can be played (generated) on Linux.  

## Configuring Audio

The script will read the audio configuration from a file 'audio_config.toml' from the same directory where the script is ran.  
The device index can be tricky, as it may be different from machine to machine.  
For that matter, it is best to see the list of Audio devices from within a Julia REPL, and remember the number of the required audio output device.  
```julia
using PortAudio
PortAudio.devices()
```

Notice, that the module requires us to specify both the input and the output device, even if we only really need the output device.  
