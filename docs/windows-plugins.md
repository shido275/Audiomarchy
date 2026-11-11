# Windows plugins, iLok, Waves and Native Instruments

Audiomarchy can run Windows VST2/VST3 plugins through Wine and yabridge, and
it automates the parts that are mechanical: a dedicated prefix, a matching
bridge build, registering plugin folders, rescanning, and diagnosing a broken
setup.

It cannot make a vendor support Linux, and it does not touch copy protection.
iLok, Waves and Native Instruments each behave differently under Wine, and
"works" often means "works for this plugin version, on this Wine build, today".
That is the honest state of the art, not a limitation of the overlay.

## What the overlay sets up

- `wine-staging` and `winetricks` from the Arch repos.
- A yabridge build that matches your Wine version. Upstream yabridge 5.1.1
  cannot host plugins under Wine 9.22 or newer; Arch ships Wine 11, so the
  installer switches to `yabridge-wine10-git` + `yabridgectl-wine10-git`
  from the AUR. If it finds an old Wine instead, it keeps the stable build.
- A studio Wine prefix at `~/.wine-audiomarchy` (override with
  `AUDIOMARCHY_WINE_PREFIX`), set to Windows 10, with the standard VST
  folders inside it registered with yabridgectl.

Keeping one prefix for audio means a plugin installer cannot break your other
Wine apps, and an iLok machine ID stays attached to a prefix you can back up.

## Install any Windows plugin

```bash
audiomarchy plugins install ~/Downloads/Serum2Installer.exe
```

That creates/uses the prefix, runs the installer, looks for new `.vst3`
bundles and plugin DLLs, registers their folders, and runs `yabridgectl sync`.
Use `--no-sync` to skip the last step. With no argument, the menu action opens
a file picker.

After it finishes, rescan plugins in your DAW. Bridged plugins appear under
`~/.vst` (VST2) and `~/.vst3` (VST3).

```bash
audiomarchy plugins sync      # rescan Windows plugin folders
audiomarchy plugins list      # what is installed and bridged
audiomarchy plugins doctor    # Wine, yabridge and vendor diagnostics
```

## iLok

There is no iLok or PACE support for Linux. There is no Linux kernel driver,
and a **USB iLok dongle will not work** — Wine cannot talk to it the way the
Windows driver does.

What sometimes works:

- **Software licenses and iLok Cloud.** People do get iLok-authorized plugins
  running, but results are plugin-specific and version-sensitive.
- **iLok License Manager 5.6.1** is the version most often reported to install
  cleanly. Newer installers often fail their prerequisite checks under Wine.
- **Activate to "this computer"**, not to a dongle, and keep the prefix stable
  afterwards. Changing Wine versions or recreating the prefix can change the
  machine ID, which burns an activation.

```bash
audiomarchy plugins vendor ilok          # guidance, or launch it if installed
audiomarchy plugins install ~/Downloads/iLokLicenseManagerSetup.exe
audiomarchy plugins prefix backup        # before any Wine upgrade
```

`audiomarchy plugins prefix backup` tars the whole prefix into
`~/.local/state/audiomarchy/wine-backups/`. Restore only while no plugin or
DAW is running:

```bash
tar -xzf ~/.local/state/audiomarchy/wine-backups/prefix-YYYYmmdd-HHMMSS.tar.gz \
  -C ~
```

Some iLok plugins load but hang the scan when the License Manager is not
running. If a DAW scan freezes on a bridged plugin, remove that plugin from
yabridgectl (`yabridgectl rm <path>`) and try again with the License Manager
open.

## Waves

Waves Central generally installs and activates under Wine:

1. Download Waves Central from <https://www.waves.com/downloads/central>.
2. `audiomarchy plugins install <WavesCentralSetup.exe>`
3. Launch it: `audiomarchy plugins vendor waves`
4. Activate to **this computer (Windows 10)**, not to a USB drive.
5. Install the plugins, then `audiomarchy plugins sync`.

Notes:

- **v13/v14 are the most reliable.** VST3 versions of v13 have memory issues;
  v15 and newer have known crashes under Wine 10/11, and WaveShell sometimes
  needs a rescan before all plugins appear.
- WaveShell is one big plugin hosting many Waves effects. If one plugin is
  missing, `yabridgectl sync` may still have worked — rescan in the DAW.
- Offline installers from Waves work better than the online flow when an
  installer stalls.

## Native Instruments

Native Access 2 is Electron-based and generally does not start under Wine.
Native Instruments plugins themselves mostly do.

Options, best first:

1. **Legacy Native Access 1.x** installs and activates under Wine. Install it
   with `audiomarchy plugins install`, then install products from it.
2. **The community "NI on Linux" package** wraps a private Wine environment
   with the font/runtime/stack fixes Native Access needs. Search for
   `native-instruments` on GitHub.
3. **Kontakt 7 works; Kontakt 8 is unreliable.** If you need Kontakt 8, test
   with a demo library before buying.

Native Instruments does not support Linux, and activation happens against
their servers exactly as on Windows.

## When a plugin refuses to work

| Symptom | Try |
|---|---|
| Black or empty editor | Disable `d2d1` for that prefix (winecfg → Libraries), or install `corefonts` with `audiomarchy plugins prefix deps` |
| Clicks land in the wrong place | The `xwayland { force_zero_scaling = true }` rule in `config/hypr/audiomarchy.conf` — reinstate it |
| `yabridgectl sync` finds nothing | Install to `Common Files/VST3` or `VstPlugins`; run `audiomarchy plugins install` again so discovery registers the folder |
| Plugin crashes at scan | Run with `YABRIDGE_DEBUG_FILE=/tmp/yabridge.log YABRIDGE_DEBUG_LEVEL=2`, check the log, then remove the bridge |
| Worked before a Wine update | Keep the prefix backup; Wine regressions are common. Arch's `downgrade` can return to the previous wine-staging |
| "Not authorized" | The license daemon is not running. Launch the vendor app inside the same prefix and activate again |
| Everything broke after recreating the prefix | iLok machine ID changed. Restore the prefix backup rather than reactivating |

Useful details:

```bash
audiomarchy plugins prefix status   # where the prefix is and how big
audiomarchy plugins prefix deps     # corefonts + VC++ runtime
audiomarchy plugins prefix open     # browse drive_c
audiomarchy plugins prefix backup
```

Debug a single bridged plugin:

```bash
YABRIDGE_DEBUG_FILE=/tmp/yabridge.log YABRIDGE_DEBUG_LEVEL=2 \
  reaper   # then load the plugin and read /tmp/yabridge.log
```

## What will not work

- A USB iLok dongle. No Linux driver exists.
- Kernel-level anti-tamper and some hardware fingerprinting.
- Installers that need a full Windows shell, Internet Explorer, or WebView2.
- 32-bit plugins in a 64-bit-only prefix. Multilib/wow64 is enabled on
  Omarchy, so most 64-bit installers are fine.
- Vendor support. None of these vendors support Linux; activation and
  licensing remain their systems, and Audiomarchy does not bypass them.

Install only software you have licensed. The overlay automates Wine setup and
plugin discovery, nothing else.
