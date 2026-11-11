# Plugins

Linux has native CLAP, LV2, VST3 and VST2. Audiomarchy installs native
bundles where they exist and bridges Windows plugins where they do not.

## The folders

```
~/.vst      VST2 (32/64-bit, as yabridge produces)
~/.vst3     VST3
~/.lv2      LV2
~/.clap     CLAP
```

`audiomarchy plugins dirs` creates them. Point every DAW's plugin scanner at
these four paths once; they are the convention every Linux plugin uses.

## Native bundles

The core installs these, and the Music menu opens their install folder so you
can see what is actually there:

| Package | Format | Notes |
|---|---|---|
| `lsp-plugins` | LV2, VST3, CLAP | EQ, dynamics, limiter, reverb, meters |
| `calf` | LV2 | classic effects and instruments |
| `dragonfly-reverb` | LV2, VST3 | halls, rooms, plates |
| `x42-plugins` | LV2 | meters and creative effects |
| `zam-plugins` | LV2, VST3 | mastering chain |
| `surge-xt` | LV2, VST3, CLAP | hybrid synth |
| `sfizz` | LV2, VST3 | SFZ sampler |
| `vital` | LV2, VST3 | wavetable synth (AUR) |
| `cardinal` | LV2, VST3 | modular rack |

## Windows plugins (yabridge)

```bash
audiomarchy plugins scan
```

That runs `yabridgectl sync`. The workflow:

1. Put the Windows `.dll` (VST2) or `.vst3` bundle somewhere permanent, e.g.
   `~/.wine/drive_c/Program Files/Common Files/VST3/`.
2. `yabridgectl add "<that folder>"` once.
3. `yabridgectl sync` — it writes Linux-side `.so`/`.vst3` entries into your
   plugin folders.
4. Rescan in the DAW.

`audiomarchy plugins status` shows what yabridgectl knows about.

### Wine prefix

The installer creates `~/.wine-audiomarchy` and records it in
`~/.config/audiomarchy/wine-prefix`. `audiomarchy plugins install` runs
installers there, and yabridge derives the prefix from the plugin paths it was
given, so you do not need to export `WINEPREFIX` for your DAW.

```bash
audiomarchy plugins prefix status
audiomarchy plugins prefix init
audiomarchy plugins prefix backup
```

### iLok, Waves and Native Instruments

iLok is not simply "unsupported": many iLok plugins run, some do not, and a
USB iLok dongle cannot work because PACE needs a Windows kernel driver. Waves
and Native Instruments have their own quirks. The installer sets up a
dedicated prefix and a matching yabridge build, and the CLI has vendor
helpers:

```bash
audiomarchy plugins install ~/Downloads/PluginSetup.exe
audiomarchy plugins vendor ilok      # also: waves, ni
audiomarchy plugins doctor
audiomarchy plugins prefix backup
```

See [windows-plugins.md](windows-plugins.md) for the compatibility notes and
what to do when a plugin refuses to authorize.

Still out of reach: kernel-level anti-tamper, installers that need a full
Windows shell, and 32-bit plugins in a 64-bit-only prefix.

## Why the window rules matter

Bridged plugin editors are XWayland windows. Two Hyprland rules in
`~/.config/hypr/audiomarchy.conf` make them usable:

- `float on` for `yabridge` and `*.exe` windows, so editors are not tiled into
  the layout.
- `xwayland { force_zero_scaling = true }`, so a fractional display scale does
  not blur the editor or offset the mouse.

The second one is the fix for "the plugin UI is blurry and clicks land in the
wrong place", which is the most common Wayland-plugin complaint.
