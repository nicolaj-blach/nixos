import AstalBattery from "gi://AstalBattery"
import { createPoll } from "ags/time"

// Nerd Font battery icons mapped to charge level
function batteryIcon(percentage: number, charging: boolean): string {
  if (charging) {
    if (percentage >= 90) return "\u{f0085}" // nf-md-battery_charging_100
    if (percentage >= 80) return "\u{f008b}" // nf-md-battery_charging_90
    if (percentage >= 60) return "\u{f008a}" // nf-md-battery_charging_70
    if (percentage >= 40) return "\u{f0088}" // nf-md-battery_charging_50
    if (percentage >= 20) return "\u{f0087}" // nf-md-battery_charging_30
    if (percentage >= 10) return "\u{f0086}" // nf-md-battery_charging_20
    return "\u{f0084}" // nf-md-battery_charging
  }
  if (percentage >= 90) return "\u{f0079}" // nf-md-battery
  if (percentage >= 80) return "\u{f0082}" // nf-md-battery_90
  if (percentage >= 60) return "\u{f0081}" // nf-md-battery_70
  if (percentage >= 40) return "\u{f007f}" // nf-md-battery_50
  if (percentage >= 20) return "\u{f007e}" // nf-md-battery_30
  if (percentage >= 10) return "\u{f007c}" // nf-md-battery_20
  return "\u{f008e}" // nf-md-battery_alert
}

function readBattery(): { percentage: number; charging: boolean } {
  try {
    const battery = AstalBattery.get_default()
    const p = Math.round((battery.percentage ?? 0) * 100)
    const c = battery.charging ?? false
    return { percentage: p, charging: c }
  } catch (e) {
    console.error("battery read error:", e)
    return { percentage: -1, charging: false }
  }
}

export default function Battery() {
  const init = readBattery()

  const icon = createPoll(batteryIcon(init.percentage, init.charging), 5000, () => {
    const { percentage, charging } = readBattery()
    return batteryIcon(percentage, charging)
  })

  const text = createPoll(`${init.percentage}%`, 5000, () => {
    const { percentage } = readBattery()
    return `${percentage}%`
  })

  const chargingClass = createPoll(
    init.charging ? "battery charging" : "battery",
    5000,
    () => {
      const { charging } = readBattery()
      return charging ? "battery charging" : "battery"
    },
  )

  const chargingMargin = createPoll(init.charging ? 6 : 0, 5000, () => {
    const { charging } = readBattery()
    return charging ? 6 : 0
  })

  return (
    <box class={chargingClass} spacing={4}>
      <label class="battery-icon" label={icon} />
      <label class="battery-text" label={text} marginStart={chargingMargin} />
    </box>
  )
}
