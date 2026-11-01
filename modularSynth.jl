using PortAudio
using TOML
using SampledSignals

struct AudioConfig
  device_name::String
  sample_rate::Int
  channels::Int
end

struct Note
  freq::Float64
  duration::Float64
  amplitude::Float64
  generator::Function
end

struct HarmonicSettings
  num_harmonics::Int
  harmonic_amp::Float64
  falloff::Float64
end

# === Waveform generators ===
sine_wave(freq, t) = sin.(2 * pi * freq .* t)

square_wave(freq, t) = sign.(sin.(2 * pi * freq .* t))

function harmonic_wave_static(freq, t)
  return sin.(2 * pi * freq .* t) + (1/3) * sin.(2 * pi * 3 * freq .* t) + (1/5) * sin.(2 * pi * 5 * freq .* t) + (1/7) * sin.(2 * pi * 7 * freq .* t)
end

function harmonic_generator(settings::HarmonicSettings)
  """
  make_harmonic_generator(num_harmonics::Int, harmonic_amp::Float64, falloff::Float64)
  function factory: function that generates function dynamically

  Returns a waveform generator function with:
  - `num_harmonics`: number of odd harmonics (excluding the fundamental)
  - `harmonic_amp`: amplitude of first harmonic relative to the base frequency
  - `falloff`: per-harmonic attenuation factor
  """
  return function(freq::Float64, t)
    waveform = sin.(2π * freq .* t)
    for i in 1:settings.num_harmonics
      overtone = 2i + 1
      attenuation = settings.harmonic_amp / (settings.falloff ^ (i - 1))
      waveform .+= attenuation .* sin.(2π * overtone * freq .* t)
    end
    return waveform
  end
end

# === Load Configuration ===
function load_config(path)
  let cfg = TOML.parsefile(path)
    AudioConfig(cfg["device_name"], cfg["sample_rate"], cfg["channels"])
  end
end

# === Generate the waveform ===
function generate_wave(note::Note, sample_rate::Int)
  n = round(Int, note.duration * sample_rate)
  t = (0:n-1) ./ sample_rate
  return note.amplitude .* note.generator(note.freq, t)
end

# === Play note ===
function play_note(cfg::AudioConfig, note::Note)
  sig = generate_wave(note, cfg.sample_rate)

  audio_data = if cfg.channels == 1
    Float32.(sig)
  elseif cfg.channels == 2
    Float32.(hcat(sig, sig))
  else
    error("Only 1 or 2 channels supported")
  end

  stream = PortAudioStream(cfg.device_name, 0, cfg.channels;
                           samplerate=cfg.sample_rate)
  try
    write(stream, audio_data)
    sleep(0.2)          # let the last buffer drain before closing
  finally
    close(stream)
  end
end

function main()
  cfg = load_config("audio_config.toml")
  harmonic_generator_settings = HarmonicSettings(10, 0.04, 1.4)
  gen_harmonics = harmonic_generator(harmonic_generator_settings)
  note = Note(440.0, 2.0, 0.5, gen_harmonics)
  play_note(cfg, note)
end

main()

