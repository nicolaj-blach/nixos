import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createState, createComputed } from "ags"

// Monitor workspace mapping:
// DP-1 (center):    1-9   (offset 0)
// HDMI-A-1 (left): 11-19  (offset 10)
// DP-2 (right):    21-29  (offset 20)
// Other/laptop:     1-9   (offset 0)
function getWorkspaceOffset(monitorName: string): number {
  switch (monitorName) {
    case "DP-1": return 0
    case "HDMI-A-1": return 10
    case "DP-2": return 20
    default: return 0
  }
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
