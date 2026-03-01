import GLib from "gi://GLib"
import { createPoll } from "ags/time"

function getTime(): string {
  return GLib.DateTime.new_now_local().format("%H:%M")!
}

function getDate(): string {
  return GLib.DateTime.new_now_local().format("%d %b")!
}

function getDay(): string {
  return GLib.DateTime.new_now_local().format("%a")!
}

function getWeek(): string {
  const week = GLib.DateTime.new_now_local().get_week_of_year()
  return `W${week.toString().padStart(2, "0")}`
}

export default function Clock() {
  const time = createPoll("", 1000, getTime)
  const date = createPoll("", 60000, getDate)
  const day = createPoll("", 60000, getDay)
  const week = createPoll("", 60000, getWeek)

  return (
    <box class="clock" spacing={12}>
      <label class="clock-time" label={time} />
      <label class="clock-separator" label="|" />
      <label class="clock-date" label={date} />
      <label class="clock-separator" label="|" />
      <label class="clock-day" label={day} />
      <label class="clock-separator" label="|" />
      <label class="clock-week" label={week} />
    </box>
  )
}
