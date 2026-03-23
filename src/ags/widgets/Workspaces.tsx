import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createState, createComputed } from "ags"

// split-monitor-workspaces plugin workspace mapping:
// Each monitor gets 10 workspace slots (1-9 visible, 10 reserved)
// Monitor index 0: workspaces 1-9
// Monitor index 1: workspaces 11-19
// Monitor index 2: workspaces 21-29
// The plugin assigns monitor indices in the order monitors are added
const WORKSPACES_PER_MONITOR = 10

function getMonitorWorkspaceRange(monitorName: string): { offset: number; count: number } {
  const hyprland = AstalHyprland.get_default()
  const monitors = hyprland.get_monitors()

  // Single monitor - no offset needed
  if (monitors.length === 1) return { offset: 0, count: 9 }

  // Find monitor index (plugin uses internal order)
  const monitorIndex = monitors.findIndex((m) => m.name === monitorName)
  if (monitorIndex === -1) return { offset: 0, count: 9 }

  return { offset: monitorIndex * WORKSPACES_PER_MONITOR, count: 9 }
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

  const { offset, count } = getMonitorWorkspaceRange(monitor)

  return (
    <box class="workspaces">
      {Array.from({ length: count }, (_, i) => i + 1).map((displayId) => {
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
            onClicked={() => hyprland.dispatch("split-workspace", `${displayId}`)}
          >
            <label label={`${displayId}`} />
          </button>
        )
      })}
    </box>
  )
}
