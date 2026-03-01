import AstalHyprland from "gi://AstalHyprland"
import { createBinding } from "ags"

export default function Workspaces() {
  const hyprland = AstalHyprland.get_default()
  const focused = createBinding(hyprland, "focusedWorkspace")

  return (
    <box class="workspaces">
      {Array.from({ length: 10 }, (_, i) => i + 1).map((id) => (
        <button
          class={focused((fw) =>
            fw?.id === id ? "workspace active" : "workspace"
          )}
          onClicked={() => hyprland.dispatch("workspace", `${id}`)}
        >
          <label label={`${id}`} />
        </button>
      ))}
    </box>
  )
}
