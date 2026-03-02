import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createComputed } from "ags"

export default function Workspaces() {
  const hyprland = AstalHyprland.get_default()
  const focused = createBinding(hyprland, "focusedWorkspace")
  const clients = createBinding(hyprland, "clients")

  return (
    <box class="workspaces">
      {Array.from({ length: 10 }, (_, i) => i + 1).map((id) => {
        const cls = createComputed(() => {
          const fw = focused()
          const cl = clients()
          if (fw?.id === id) return "workspace active"
          const occupied = cl.some(
            (c: AstalHyprland.Client) => c.get_workspace()?.id === id,
          )
          if (occupied) return "workspace occupied"
          return "workspace"
        })

        return (
          <button
            class={cls}
            onClicked={() => hyprland.dispatch("workspace", `${id}`)}
          >
            <label label={`${id}`} />
          </button>
        )
      })}
    </box>
  )
}
