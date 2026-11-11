# Session mode

Session mode is the studio equivalent of Focus: everything that can interrupt
a take is turned off, and the buffer is tightened, for as long as the session
runs. It is built to be safe to leave running and to put everything back
exactly as it was.

```bash
audiomarchy session start "Vocal comping"
audiomarchy session start --offline     # also turns Wi-Fi off
audiomarchy session status
audiomarchy session stop
```

The same start/stop actions are under **Trigger → Music**.

## What it changes

| Thing | Session value | Restored to |
|---|---|---|
| Power profile | `performance` | whatever `powerprofilesctl get` said |
| Notifications | `do-not-disturb` added | removed only if it was not already on |
| Idle / suspend / lid | inhibited by a `systemd-inhibit` lock | lock released |
| Buffer | `clock.force-quantum = 128` | the force value before the session |
| Wi-Fi (`--offline`) | off | on |

Every value is written to `~/.local/state/audiomarchy/session/` as it is
changed. `session stop` reads those files rather than assuming defaults, which
is what makes it safe on a machine where you already had DND on or were
already on `performance`.

The buffer change is runtime-only. Session mode does not rewrite your saved
latency profile, so stopping a session does not quietly change how the next
one starts.

## Notifications still work

Mako's `do-not-disturb` mode hides notifications, but the Omarchy config keeps
`notify-send` visible inside it. Audiomarchy uses `notify-send`, so the
session start/stop confirmation and the latency notifications still appear
while everything else is silent.

## If a session is interrupted

If the machine crashes or the session process is killed, the state directory
survives. Run `audiomarchy session stop`; it restores what it can and clears
the marker. `audiomarchy doctor` is the next stop if audio still looks wrong.
