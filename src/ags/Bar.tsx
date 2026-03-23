import app from "ags/gtk4/app"
import Astal from "gi://Astal?version=4.0"
import Gdk from "gi://Gdk?version=4.0"
import { onCleanup } from "ags"
import Workspaces from "./widgets/Workspaces"
import Clock from "./widgets/Clock"
import Battery from "./widgets/Battery"
import Volume from "./widgets/Volume"
import Bluetooth from "./widgets/Bluetooth"
import Network from "./widgets/Wifi"

export default function Bar({ gdkmonitor }: { gdkmonitor: Gdk.Monitor }) {
  let win: Astal.Window
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  console.log(`Bar created: connector=${gdkmonitor.connector}, geometry=${JSON.stringify(gdkmonitor.geometry)}`)

  onCleanup(() => {
    win.destroy()
  })

  return (
    <window
      $={(self) => (win = self)}
      visible
      class="Bar"
      namespace="bar"
      name={`bar-${gdkmonitor.connector}`}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={TOP | LEFT | RIGHT}
      application={app}
    >
      <centerbox>
        <box $type="start" class="bar-start">
          <Workspaces monitor={gdkmonitor.connector ?? ""} />
        </box>
        <box $type="center" class="bar-center">
          <Clock />
        </box>
        <box $type="end" class="bar-end">
          <Battery />
          <Volume />
          <Bluetooth />
          <Network />
        </box>
      </centerbox>
    </window>
  )
}
