import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createState, createComputed } from "ags"

function getOccupiedIds(hyprland: AstalHyprland.Hyprland): Set<number> {
  const ids = new Set<number>()
  for (const c of hyprland.get_clients()) {
    const wsId = c.get_workspace()?.id
    if (wsId != null) ids.add(wsId)
  }
  return ids
}

export default function Workspaces() {
  const hyprland = AstalHyprland.get_default()
  const focused = createBinding(hyprland, "focusedWorkspace")
  const [occupied, setOccupied] = createState(getOccupiedIds(hyprland))

  const refresh = () => setOccupied(getOccupiedIds(hyprland))
  hyprland.connect("client-added", refresh)
  hyprland.connect("client-removed", refresh)
  hyprland.connect("client-moved", refresh)

  return (
    <box class="workspaces">
      {Array.from({ length: 10 }, (_, i) => i + 1).map((id) => {
        const cls = createComputed(() => {
          const fw = focused()
          if (fw?.id === id) return "workspace active"
          if (occupied().has(id)) return "workspace occupied"
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
