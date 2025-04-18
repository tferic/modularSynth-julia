using PortAudio
using TOML
using SampledSignals

struct AudioConfig
  device_index_input::Int
  device_index_output::Int
  sample_rate::Int
  channels::Int
end

struct Note
  freq::Float64
  duration::Float64
  amplitude::Float64
  generator::Function
end

# === Waveform generators ===
sine_wave(freq, t) = sin.(2 * pi * freq .* t)
square_wave(freq, t) = sign.(sin.(2 * pi * freq .* t))
function harmonic_wave(freq, t)
  return sin.(2 * pi * freq .* t) + (1/3) * sin.(2 * pi * 3 * freq .* t) + (1/5) * sin.(2 * pi * 5 * freq .* t) + (1/7) * sin.(2 * pi * 7 * freq .* t)
end

# === Load Configuration ===
function load_config(path::String)::AudioConfig
  cfg = TOML.parsefile(path)
  return AudioConfig(cfg["device_index_input"], cfg["device_index_output"], cfg["sample_rate"], cfg["channels"])
end

# === Generate the waveform ===
function generate_wave(note::Note, sample_rate::Int)
  num_samples = Int(round(note.duration * sample_rate))
  t = range(0, note.duration, length=num_samples)
  return note.amplitude .* note.generator(note.freq, t)
end

# === Play note ===
function play_note(cfg::AudioConfig, note::Note)
  PortAudio.initialize()

  dev_input = PortAudio.devices()[cfg.device_index_input]
  dev_output = PortAudio.devices()[cfg.device_index_output]
  sig = generate_wave(note, cfg.sample_rate)

  # Mono or Stereo
  if cfg.channels == 2
    audio_data = hcat(sig, sig)
  elseif cfg.channels == 1
    audio_data = sig
  else
    error("Only 1 or 2 channels supported")
  end

  stream = PortAudioStream(dev_input, dev_output, 0, cfg.channels; samplerate=cfg.sample_rate, eltype=Float32)

  write(stream, sig)
  close(stream)
  PortAudio.terminate()
end

function main()
  cfg = load_config("audio_config.toml")
  note = Note(440.0, 2.0, 0.5, harmonic_wave)
  play_note(cfg, note)
end

main()

