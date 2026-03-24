import AstalHyprland from "gi://AstalHyprland"
import { createBinding, createState, createComputed } from "ags"

// split-monitor-workspaces plugin workspace mapping:
// Each monitor gets `count` workspaces (configured in hyprland.conf)
// Offset is calculated as: monitorID * count
// Monitor ID 0: workspaces 1-9 (offset 0)
// Monitor ID 1: workspaces 10-18 (offset 9)
// Monitor ID 2: workspaces 19-27 (offset 18)
const WORKSPACES_PER_MONITOR = 9

function getMonitorWorkspaceRange(monitorName: string): { offset: number; count: number; monitorId: number } {
  const hyprland = AstalHyprland.get_default()
  const monitors = hyprland.get_monitors()

  // Single monitor - no offset needed
  if (monitors.length === 1) return { offset: 0, count: WORKSPACES_PER_MONITOR, monitorId: 0 }

  // Find monitor by name and use its ID for offset calculation
  const monitor = monitors.find((m) => m.name === monitorName)
  if (!monitor) return { offset: 0, count: WORKSPACES_PER_MONITOR, monitorId: 0 }

  // Plugin uses monitor.id * count for offset
  return { offset: monitor.id * WORKSPACES_PER_MONITOR, count: WORKSPACES_PER_MONITOR, monitorId: monitor.id }
}

function getOccupiedIds(hyprland: AstalHyprland.Hyprland): Set<number> {
  const ids = new Set<number>()
  for (const c of hyprland.get_clients()) {
    const wsId = c.get_workspace()?.id
    if (wsId != null) ids.add(wsId)
  }
  return ids
}

// Get the active workspace ID for a specific monitor
function getMonitorActiveWorkspace(hyprland: AstalHyprland.Hyprland, monitorName: string): number | null {
  const monitor = hyprland.get_monitors().find((m) => m.name === monitorName)
  return monitor?.activeWorkspace?.id ?? null
}

export default function Workspaces({ monitor }: { monitor: string }) {
  const hyprland = AstalHyprland.get_default()
  const focusedMonitor = createBinding(hyprland, "focusedMonitor")
  const [occupied, setOccupied] = createState(getOccupiedIds(hyprland))
  const [monitorActiveWs, setMonitorActiveWs] = createState(getMonitorActiveWorkspace(hyprland, monitor))

  const refresh = () => setOccupied(getOccupiedIds(hyprland))
  hyprland.connect("client-added", refresh)
  hyprland.connect("client-removed", refresh)
  hyprland.connect("client-moved", refresh)

  // Track workspace changes on this monitor
  hyprland.connect("notify::focused-workspace", () => {
    setMonitorActiveWs(getMonitorActiveWorkspace(hyprland, monitor))
  })

  const { offset, count } = getMonitorWorkspaceRange(monitor)

  // Get keybind number based on physical position (left to right by x-coordinate)
  const monitors = hyprland.get_monitors()
  const sortedByX = [...monitors].sort((a, b) => a.x - b.x)
  const monitorKey = sortedByX.findIndex((m) => m.name === monitor) + 1
  const showMonitorKey = monitors.length > 1

  return (
    <box class="workspaces">
      {showMonitorKey && <label label={`[${monitorKey}]`} class="monitor-key" />}
      {Array.from({ length: count }, (_, i) => i + 1).map((displayId) => {
        const actualId = displayId + offset

        const cls = createComputed(() => {
          const isActiveOnMonitor = monitorActiveWs() === actualId
          const isMonitorFocused = focusedMonitor()?.name === monitor
          const isOccupied = occupied().has(actualId)

          if (isActiveOnMonitor) {
            // Active workspace on focused monitor = blue underline
            // Active workspace on unfocused monitor = gray underline, purple text if occupied
            if (isMonitorFocused) return "workspace active"
            if (isOccupied) return "workspace active-unfocused occupied"
            return "workspace active-unfocused"
          }
          if (isOccupied) return "workspace occupied"
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
