import AstalNetwork from "gi://AstalNetwork"
import { createBinding, With } from "ags"
import { execAsync } from "ags/process"

// Nerd Font wifi icons mapped to signal strength
function wifiIcon(strength: number): string {
  if (strength >= 75) return "\u{f0928}" // nf-md-wifi_strength_4
  if (strength >= 50) return "\u{f0927}" // nf-md-wifi_strength_3
  if (strength >= 25) return "\u{f0922}" // nf-md-wifi_strength_2
  if (strength > 0) return "\u{f0921}" // nf-md-wifi_strength_1
  return "\u{f092b}" // nf-md-wifi_strength_off
}

function disconnectedIcon(): string {
  return "\u{f092b}" // nf-md-wifi_strength_off
}

export default function Wifi() {
  const network = AstalNetwork.get_default()
  const wifi = createBinding(network, "wifi")

  return (
    <button class="wifi" onClicked={() => execAsync("tui-wifi")}>
      <With value={wifi}>
        {(w) => {
          if (!w) return <label class="wifi-icon" label={disconnectedIcon()} />

          const strength = createBinding(w, "strength")
          const ssid = createBinding(w, "ssid")

          const icon = strength((s) => wifiIcon(s))

          return (
            <box spacing={8}>
              <label class="wifi-icon" label={icon} />
              <label class="wifi-ssid" label={ssid((s) => s ?? "")} />
            </box>
          )
        }}
      </With>
    </button>
  )
}
