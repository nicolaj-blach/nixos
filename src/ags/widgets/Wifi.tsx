import AstalNetwork from "gi://AstalNetwork"
import GLib from "gi://GLib"
import { createBinding, createComputed } from "ags"

// Nerd Font icons
const ETHERNET_ICON = "\u{f0200}" // nf-md-ethernet
const WIFI_OFF_ICON = "\u{f092b}" // nf-md-wifi_strength_off

function wifiIcon(strength: number): string {
  if (strength >= 75) return "\u{f0928}" // nf-md-wifi_strength_4
  if (strength >= 50) return "\u{f0927}" // nf-md-wifi_strength_3
  if (strength >= 25) return "\u{f0922}" // nf-md-wifi_strength_2
  if (strength > 0) return "\u{f0921}" // nf-md-wifi_strength_1
  return WIFI_OFF_ICON
}

export default function Network() {
  const network = AstalNetwork.get_default()
  const wifi = network.wifi

  const primary = createBinding(network, "primary")
  const isWired = createComputed(() => primary() === AstalNetwork.Primary.WIRED)

  // Create reactive bindings for wifi properties
  const strength = wifi ? createBinding(wifi, "strength") : () => 0
  const ssidBinding = wifi ? createBinding(wifi, "ssid") : () => null

  // Icon: ethernet if wired, otherwise wifi strength
  const icon = createComputed(() => {
    if (isWired()) return ETHERNET_ICON
    if (!wifi) return WIFI_OFF_ICON
    return wifiIcon(strength())
  })

  // SSID: empty if wired, otherwise wifi ssid
  const ssid = createComputed(() => {
    if (isWired()) return ""
    if (!wifi) return ""
    return ssidBinding() ?? ""
  })

  // Only show SSID label when not wired
  const showSsid = () => !isWired()

  return (
    <button class="wifi" onClicked={() => GLib.spawn_command_line_async(`${GLib.get_home_dir()}/.local/bin/tui-wifi`)}>
      <box spacing={4}>
        <label class="wifi-icon" label={icon} />
        <label class="wifi-ssid" label={ssid} visible={showSsid} />
      </box>
    </button>
  )
}
