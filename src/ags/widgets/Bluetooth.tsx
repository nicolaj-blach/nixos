import AstalBluetooth from "gi://AstalBluetooth"
import GLib from "gi://GLib"
import { createBinding } from "ags"

// Nerd Font bluetooth icons
function bluetoothIcon(powered: boolean, connected: boolean): string {
  if (!powered) return "\u{f00b2}" // nf-md-bluetooth_off
  if (connected) return "\u{f00b0}" // nf-md-bluetooth_connect
  return "\u{f00af}" // nf-md-bluetooth
}

export default function Bluetooth() {
  const bt = AstalBluetooth.get_default()

  const powered = createBinding(bt, "isPowered")
  const connected = createBinding(bt, "isConnected")

  const icon = powered((p) => bluetoothIcon(p, bt.isConnected))
  const cls = powered((p) => (p ? "bluetooth" : "bluetooth off"))

  return (
    <button class={cls} onClicked={() => GLib.spawn_command_line_async(`${GLib.get_home_dir()}/.local/bin/tui-bluetooth`)}>
      <label class="bluetooth-icon" label={icon} />
    </button>
  )
}
