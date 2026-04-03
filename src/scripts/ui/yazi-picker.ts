#!/usr/bin/env bun
// Yazi file picker: opens files or directories picked from a floating terminal.
// Launched via SUPER+SHIFT+E.
//
// Uses --chooser-file so yazi writes the picked path and exits on 'open'.
//
// - Enter on any item: yazi writes path to chooser-file and exits
//   - Text/code file: opens in $EDITOR in a new terminal
//   - Other file (image, pdf, etc.): opens with xdg-open
//   - Directory: opens terminal there
// - l/h to navigate directories (standard yazi nav)
// - q to quit: does nothing

import { readFileSync, unlinkSync, existsSync, statSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

const home = Bun.env.HOME!;
const editor = Bun.env.EDITOR ?? "nvim";

function shellEscape(s: string): string {
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

function tempFile(): string {
  const name = `yazi-picker-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  return join(tmpdir(), name);
}

function readAndClean(path: string): string {
  try {
    if (existsSync(path) && statSync(path).size > 0) {
      return readFileSync(path, "utf-8").trim();
    }
  } catch {}
  return "";
}

async function needsTerminal(filepath: string): Promise<boolean> {
  // Get MIME type
  const mimeProc = Bun.spawn(["xdg-mime", "query", "filetype", filepath], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const mime = (await new Response(mimeProc.stdout).text()).trim();
  if (!mime || (await mimeProc.exited) !== 0) return false;

  // Get default handler
  const handlerProc = Bun.spawn(["xdg-mime", "query", "default", mime], {
    stdout: "pipe",
    stderr: "pipe",
  });
  const handler = (await new Response(handlerProc.stdout).text()).trim();
  if (!handler || (await handlerProc.exited) !== 0) return false;

  // Check if the .desktop file has Terminal=true
  const dirs = [
    `${home}/.local/share/applications`,
    "/usr/share/applications",
    "/run/current-system/sw/share/applications",
  ];

  for (const dir of dirs) {
    const desktop = join(dir, handler);
    if (existsSync(desktop)) {
      try {
        const content = readFileSync(desktop, "utf-8");
        return /^Terminal=true/im.test(content);
      } catch {
        return false;
      }
    }
  }

  return false;
}

async function hyprExec(cmd: string): Promise<void> {
  await Bun.spawn(["hyprctl", "dispatch", "exec", cmd], {
    stdout: "pipe",
    stderr: "pipe",
  }).exited;
}

async function main() {
  const chooserFile = tempFile();

  // Run yazi with picker config
  const yazi = Bun.spawn(
    ["yazi", `--chooser-file=${chooserFile}`],
    {
      env: { ...process.env, YAZI_CONFIG_HOME: `${home}/.config/yazi-picker` },
      stdout: "inherit",
      stderr: "inherit",
      stdin: "inherit",
    },
  );
  await yazi.exited;

  // Read result before cleanup
  const chosen = readAndClean(chooserFile);
  try { unlinkSync(chooserFile); } catch {}

  // Nothing picked (user quit with q)
  if (!chosen) return;

  // Use hyprctl dispatch exec to spawn independently of this terminal
  for (const selected of chosen.split("\n")) {
    if (!selected.trim()) continue;

    const escaped = shellEscape(selected);
    if (existsSync(selected) && statSync(selected).isDirectory()) {
      await hyprExec(`[silent] $TERMINAL --directory ${escaped}`);
    } else if (await needsTerminal(selected)) {
      await hyprExec(`[silent] $TERMINAL -e ${editor} ${escaped}`);
    } else {
      await hyprExec(`[silent] xdg-open ${escaped}`);
    }
  }
}

main();
