import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createState, createComputed } from "ags"

// Dynamic monitor workspace mapping based on monitor index:
// Monitor 0: workspaces 1-9   (offset 0)
// Monitor 1: workspaces 11-19 (offset 10)
// Monitor 2: workspaces 21-29 (offset 20)
// Single monitor (laptop) uses offset 0
function getWorkspaceOffset(monitorName: string): number {
  const hyprland = AstalHyprland.get_default()
  const monitors = hyprland.get_monitors()
  const index = monitors.findIndex((m) => m.name === monitorName)
  if (index === -1 || monitors.length === 1) return 0
  return index * 10
}

function getOccupiedIds(hyprland: AstalHyprland.Hyprland): Set<number> {
  const ids = new Set<number>()
  for (const c of hyprland.get_clients()) {
    const wsId = c.get_workspace()?.id
    if (wsId != null) ids.add(wsId)
  }
  return ids
}

export default function Workspaces({ monitor }: { monitor: string }) {
  const hyprland = AstalHyprland.get_default()
  const focused = createBinding(hyprland, "focusedWorkspace")
  const [occupied, setOccupied] = createState(getOccupiedIds(hyprland))

  const refresh = () => setOccupied(getOccupiedIds(hyprland))
  hyprland.connect("client-added", refresh)
  hyprland.connect("client-removed", refresh)
  hyprland.connect("client-moved", refresh)

  const offset = getWorkspaceOffset(monitor)

  return (
    <box class="workspaces">
      {Array.from({ length: 9 }, (_, i) => i + 1).map((displayId) => {
        const actualId = displayId + offset

        const cls = createComputed(() => {
          const fw = focused()
          if (fw?.id === actualId) return "workspace active"
          if (occupied().has(actualId)) return "workspace occupied"
          return "workspace"
        })

        return (
          <button
            class={cls}
            onClicked={() => hyprland.dispatch("workspace", `${actualId}`)}
          >
            <label label={`${displayId}`} />
          </button>
        )
      })}
    </box>
  )
}
