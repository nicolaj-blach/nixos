#!/usr/bin/env bun
// nixs - fzf-based NixOS generation switcher

import { c, listGenerations, type Generation } from "../lib";

function formatForFzf(gens: Generation[]): string {
  const header = `${c.blue}${c.bold}${"Gen".padEnd(6)}\t${"Date".padEnd(20)}\tDescription${c.reset}`;
  const lines = gens
    .filter((g) => !g.current)
    .map((g) => {
      const dateStr = `${c.cyan}${g.date} ${g.time}${c.reset}`;
      const desc = `${c.green}${g.description}${c.reset}`;
      return `${g.number.padEnd(6)}\t${dateStr}\t${desc}`;
    });
  return [header, ...lines].join("\n");
}

async function main() {
  const gens = await listGenerations();
  const fzfInput = formatForFzf(gens);

  const fzf = Bun.spawn(
    ["fzf", "--ansi", "--header-lines=1", "--exact", "--delimiter=\t", "--nth=1,3", "--tiebreak=begin"],
    {
      stdin: "pipe",
      stdout: "pipe",
      stderr: "inherit",
    },
  );

  fzf.stdin.write(fzfInput);
  fzf.stdin.end();

  const fzfExit = await fzf.exited;
  if (fzfExit !== 0) process.exit(0);

  const selection = await new Response(fzf.stdout).text();
  if (!selection.trim()) process.exit(0);

  const gen = selection.trim().split(/\s+/)[0];
  if (!gen) {
    console.error(`${c.red}Could not parse generation number${c.reset}`);
    process.exit(1);
  }

  console.log(`${c.cyan}Switching to generation ${gen}...${c.reset}`);

  const switchGen = await Bun.spawn(
    ["sudo", "nix-env", "--profile", "/nix/var/nix/profiles/system", "--switch-generation", gen],
    { stdout: "inherit", stderr: "inherit" },
  ).exited;

  if (switchGen !== 0) {
    console.error(`${c.red}Failed to switch generation${c.reset}`);
    process.exit(1);
  }

  const activate = await Bun.spawn(
    ["sudo", "/nix/var/nix/profiles/system/bin/switch-to-configuration", "switch"],
    { stdout: "inherit", stderr: "inherit" },
  ).exited;

  if (activate !== 0) {
    console.error(`${c.red}Failed to activate generation${c.reset}`);
    process.exit(1);
  }

  console.log(`${c.green}Switched to generation ${gen}${c.reset}`);
}

main();
