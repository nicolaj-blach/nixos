import { createBinding, For, This } from "ags"
import app from "ags/gtk4/app"
import { monitorFile } from "ags/file"
import { Astal } from "ags/gtk4"
import style from "./style.css"
import Bar from "./Bar"

const COLORS_PATH = `${GLib.get_home_dir()}/.config/ags/colors.css`

import GLib from "gi://GLib"

function loadColors() {
  try {
    const file = GLib.file_test(COLORS_PATH, GLib.FileTest.EXISTS)
    if (file) {
      app.apply_css(COLORS_PATH)
    }
  } catch (e) {
    console.error("failed to load colors:", e)
  }
}

app.start({
  css: style,
  main() {
    const monitors = createBinding(app, "monitors")

    // Load tinty-generated colors and watch for changes
    loadColors()
    monitorFile(COLORS_PATH, () => {
      app.reset_css()
      app.apply_css(style)
      loadColors()
    })

    return (
      <For each={monitors}>
        {(monitor) => (
          <This this={app}>
            <Bar gdkmonitor={monitor} />
          </This>
        )}
      </For>
    )
  },
})
