import AstalNetwork from "gi://AstalNetwork"
import GLib from "gi://GLib"
import { createBinding, createComputed } from "ags"

// Nerd Font wifi icons mapped to signal strength
function wifiIcon(strength: number): string {
  if (strength >= 75) return "\u{f0928}" // nf-md-wifi_strength_4
  if (strength >= 50) return "\u{f0927}" // nf-md-wifi_strength_3
  if (strength >= 25) return "\u{f0922}" // nf-md-wifi_strength_2
  if (strength > 0) return "\u{f0921}" // nf-md-wifi_strength_1
  return "\u{f092b}" // nf-md-wifi_strength_off
}

function ethernetIcon(): string {
  return "\u{f0200}" // nf-md-ethernet
}

function disconnectedIcon(): string {
  return "\u{f092b}" // nf-md-wifi_strength_off
}

function WiredDisplay() {
  const network = AstalNetwork.get_default()
  const wired = network.wired

  if (!wired) {
    return (
      <box spacing={8}>
        <label class="network-icon" label={ethernetIcon()} />
        <label class="network-info" label="Ethernet" />
      </box>
    )
  }

  const speed = createBinding(wired, "speed")

  return (
    <box spacing={8}>
      <label class="network-icon" label={ethernetIcon()} />
      <label class="network-info" label={speed((s) => s > 0 ? `${s} Mbps` : "Ethernet")} />
    </box>
  )
}

function WifiDisplay() {
  const network = AstalNetwork.get_default()
  const wifi = network.wifi

  if (!wifi) {
    return <label class="network-icon" label={disconnectedIcon()} />
  }

  const strength = createBinding(wifi, "strength")
  const ssid = createBinding(wifi, "ssid")
  const icon = strength((s) => wifiIcon(s))

  return (
    <box spacing={8}>
      <label class="network-icon" label={icon} />
      <label class="network-ssid" label={ssid((s) => s ?? "")} />
    </box>
  )
}

export default function Network() {
  const network = AstalNetwork.get_default()
  const primary = createBinding(network, "primary")

  const isWired = createComputed(() => primary() === AstalNetwork.Primary.WIRED)

  return (
    <button class="network" onClicked={() => GLib.spawn_command_line_async(`${GLib.get_home_dir()}/.local/bin/tui-wifi`)}>
      <box>
        <box visible={isWired}>
          <WiredDisplay />
        </box>
        <box visible={() => !isWired()}>
          <WifiDisplay />
        </box>
      </box>
    </button>
  )
}
