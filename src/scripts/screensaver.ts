#!/usr/bin/env bun
// screensaver - fullscreen terminal effect using tte with ANSI logo
// Usage: screensaver (press any key to exit, loops through random effects)

const nixdir = `${Bun.env.HOME}/nixos`;
const logoPath = `${nixdir}/assets/ansiLogo.txt`;

// Available effects that work well with ASCII art
const effects = [
  "decrypt",
  "matrix",
  "beams",
  "burn",
  "rain",
  "slide",
  "waves",
  "scattered",
  "spotlights",
  "swarm",
];

// Base16 onedark colors
const colors = {
  accent: "c678dd",    // base0E purple
  secondary: "61afef", // base0D blue
  tertiary: "e06c75",  // base08 red
  muted: "5c6370",     // base03
  fg: "abb2bf",        // base05
};

// Effect-specific configurations using base16 colors
const effectConfigs: Record<string, string[]> = {
  decrypt: [
    "--ciphertext-colors", colors.muted, colors.secondary,
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "horizontal",
    "--typing-speed", "2",
  ],
  matrix: [
    "--rain-color-gradient", colors.accent, colors.muted,
    "--highlight-color", colors.fg,
    "--rain-time", "5",
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "vertical",
  ],
  beams: [
    "--beam-gradient-stops", colors.accent, colors.secondary, colors.tertiary,
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "radial",
  ],
  burn: [
    "--burn-colors", colors.tertiary, colors.accent, colors.fg,
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "vertical",
  ],
  rain: [
    "--rain-colors", colors.accent, colors.secondary, colors.muted,
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "diagonal",
  ],
  slide: [
    "--movement-speed", "0.5",
    "--grouping", "row",
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "horizontal",
  ],
  waves: [
    "--wave-gradient-stops", colors.accent, colors.secondary, colors.tertiary,
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "horizontal",
  ],
  scattered: [
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "radial",
  ],
  spotlights: [
    "--spotlight-color", colors.accent,
    "--beam-width-ratio", "2",
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "radial",
  ],
  swarm: [
    "--base-color", colors.muted,
    "--flash-color", colors.accent,
    "--final-gradient-stops", colors.accent, colors.secondary,
    "--final-gradient-direction", "radial",
  ],
};

function pickRandomEffect(exclude?: string): string {
  const available = exclude ? effects.filter(e => e !== exclude) : effects;
  return available[Math.floor(Math.random() * available.length)];
}

function hideCursor(): void {
  process.stdout.write("\x1b[?25l");
}

function clearScreen(): void {
  process.stdout.write("\x1b[2J\x1b[H");
}

async function runEffect(effect: string): Promise<void> {
  const config = effectConfigs[effect] || [];

  // Use 0 for canvas dimensions to match terminal size
  // Center both the canvas in the terminal and the text within the canvas
  const cmd = [
    "tte",
    "-i", logoPath,
    "--canvas-width", "0",
    "--canvas-height", "0",
    "--anchor-canvas", "c",
    "--anchor-text", "c",
    effect,
    ...config,
  ];

  // Hide cursor and clear screen before each effect
  hideCursor();
  clearScreen();

  const proc = Bun.spawn(cmd, {
    stdout: "inherit",
    stderr: "pipe",
    stdin: "pipe",
  });

  await proc.exited;

  // Clear the screen immediately after tte exits to remove any trailing newline
  // Then hide cursor and move to top-left
  process.stdout.write("\x1b[2J\x1b[H\x1b[?25l");
}

async function main() {
  let running = true;
  let lastEffect: string | undefined;

  // Setup: enter alternate screen buffer, hide cursor, clear screen
  process.stdout.write("\x1b[?1049h"); // enter alternate screen buffer
  hideCursor();
  clearScreen();

  // Set up raw mode and listen for keypresses (only if TTY)
  const isTTY = process.stdin.isTTY;
  if (isTTY) {
    process.stdin.setRawMode(true);
    process.stdin.resume();
    process.stdin.on("data", () => {
      running = false;
    });
  }

  // Handle SIGINT/SIGTERM for clean exit
  const cleanup = () => {
    running = false;
  };
  process.on("SIGINT", cleanup);
  process.on("SIGTERM", cleanup);

  // Main loop: cycle through random effects
  while (running) {
    const effect = pickRandomEffect(lastEffect);
    lastEffect = effect;

    await runEffect(effect);

    // Small delay between effects (also allows keypress to register)
    if (running) {
      await Bun.sleep(500);
    }
  }

  // Cleanup
  if (isTTY) {
    process.stdin.setRawMode(false);
    process.stdin.pause();
  }
  process.stdout.write("\x1b[?25h");   // show cursor
  process.stdout.write("\x1b[?1049l"); // exit alternate screen buffer
}

main().catch((err) => {
  // Ensure cleanup on error
  process.stdout.write("\x1b[?25h");
  process.stdout.write("\x1b[?1049l");
  console.error(err);
  process.exit(1);
});
