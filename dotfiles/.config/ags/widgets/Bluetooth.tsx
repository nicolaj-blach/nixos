import AstalBluetooth from "gi://AstalBluetooth"
import { createBinding } from "ags"
import { execAsync } from "ags/process"

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
    <button class={cls} onClicked={() => execAsync("tui-bluetooth")}>
      <label class="bluetooth-icon" label={icon} />
    </button>
  )
}
