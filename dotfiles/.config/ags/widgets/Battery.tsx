import AstalBattery from "gi://AstalBattery"
import { createBinding } from "ags"

// Nerd Font battery icons mapped to charge level
function batteryIcon(percentage: number, charging: boolean): string {
  if (charging) return "\u{f0084}" // nf-md-battery_charging
  if (percentage >= 90) return "\u{f0079}" // nf-md-battery
  if (percentage >= 80) return "\u{f0082}" // nf-md-battery_90
  if (percentage >= 60) return "\u{f0081}" // nf-md-battery_70
  if (percentage >= 40) return "\u{f007f}" // nf-md-battery_50
  if (percentage >= 20) return "\u{f007e}" // nf-md-battery_30
  if (percentage >= 10) return "\u{f007c}" // nf-md-battery_20
  return "\u{f008e}" // nf-md-battery_alert
}

export default function Battery() {
  const battery = AstalBattery.get_default()

  const percent = createBinding(battery, "percentage")
  const charging = createBinding(battery, "charging")
  const isPresent = createBinding(battery, "isPresent")

  const icon = percent((p) => {
    const c = battery.charging
    return batteryIcon(Math.floor(p * 100), c)
  })

  const text = percent((p) => `${Math.floor(p * 100)}%`)

  return (
    <box class="battery" visible={isPresent} spacing={4}>
      <label class="battery-icon" label={icon} />
      <label class="battery-text" label={text} />
    </box>
  )
}
