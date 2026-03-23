import AstalWp from "gi://AstalWp"
import GLib from "gi://GLib"
import { createBinding, createComputed } from "ags"

// Nerd Font volume icons
function volumeIcon(volume: number, muted: boolean): string {
  if (muted) return "\u{f0581}" // nf-md-volume_off
  if (volume >= 0.66) return "\u{f057e}" // nf-md-volume_high
  if (volume >= 0.33) return "\u{f0580}" // nf-md-volume_medium
  if (volume > 0) return "\u{f057f}" // nf-md-volume_low
  return "\u{f0581}" // nf-md-volume_off
}

export default function Volume() {
  const wp = AstalWp.get_default()
  const speaker = wp?.defaultSpeaker

  if (!speaker) {
    return (
      <button class="volume" onClicked={() => GLib.spawn_command_line_async(`${GLib.get_home_dir()}/.local/bin/tui-audio`)}>
        <box spacing={4}>
          <label class="volume-icon" label={volumeIcon(0, true)} />
          <label class="volume-text" label="--%"  />
        </box>
      </button>
    )
  }

  const vol = createBinding(speaker, "volume")
  const muted = createBinding(speaker, "mute")

  const icon = createComputed(() => volumeIcon(vol(), muted()))

  const text = vol((v) => `${Math.round(v * 100)}%`)

  return (
    <button class="volume" onClicked={() => GLib.spawn_command_line_async(`${GLib.get_home_dir()}/.local/bin/tui-audio`)}>
      <box spacing={4}>
        <label class="volume-icon" label={icon} />
        <label class="volume-text" label={text} />
      </box>
    </button>
  )
}
