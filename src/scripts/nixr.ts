#!/usr/bin/env bun
// nixr - commit, build/switch, push, and stow in one step
// Usage: nixr <commit message>

import { $ } from "bun";
import { c, nixdir } from "./lib";

async function run(cmd: string[], opts?: { cwd?: string; env?: Record<string, string> }): Promise<boolean> {
  const proc = Bun.spawn(cmd, {
    cwd: opts?.cwd ?? nixdir,
    env: { ...process.env, ...opts?.env },
    stdout: "inherit",
    stderr: "inherit",
  });
  return (await proc.exited) === 0;
}

async function hasChanges(): Promise<boolean> {
  const output = await $`git -C ${nixdir} status --porcelain`.text();
  return output.trim().length > 0;
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    console.log(`${c.red}Usage: nixr <message>${c.reset}`);
    process.exit(1);
  }

  const msg = args.join(" ");
  let committed = false;
  let built = false;
  let pushed = false;
  let stowed = false;

  // Step 1: commit current changes if any
  if (await hasChanges()) {
    console.log(`${c.cyan}Committing changes...${c.reset}`);
    if (!(await run(["git", "-C", nixdir, "add", "-A"]))) {
      console.log(`${c.red}Git add failed${c.reset}`);
      process.exit(1);
    }
    if (!(await run(["git", "-C", nixdir, "commit", "-m", msg]))) {
      console.log(`${c.red}Commit failed${c.reset}`);
      process.exit(1);
    }
    committed = true;
  } else {
    console.log(`${c.yellow}No changes to commit, switching with existing HEAD${c.reset}`);
  }

  // Sanitize message for NixOS label (only [a-zA-Z0-9:_.-] allowed)
  const label = msg.replace(/ /g, "_").replace(/[^a-zA-Z0-9:_.-]/g, "");

  // Write label to a gitignored .nix file so flake.nix can read it without --impure
  const labelFile = `${nixdir}/nixos-label.nix`;
  await Bun.write(labelFile, `"${label}"\n`);

  // Step 2: try nh os switch
  console.log(`${c.cyan}Building and switching...${c.reset}`);
  built = await run(["nh", "os", "switch", nixdir]);

  if (built) {
    // Step 3: push on success
    console.log(`${c.cyan}Pushing...${c.reset}`);
    pushed = await run(["git", "-C", nixdir, "push"]);

    // Step 4: stow dotfiles
    console.log(`${c.cyan}Stowing dotfiles...${c.reset}`);
    const stowExit = await Bun.spawn(["stow", "-d", nixdir, "-t", Bun.env.HOME!, "--adopt", "dotfiles"], {
      stdout: "pipe",
      stderr: "pipe",
    }).exited;
    if (stowExit === 0) {
      await run(["git", "-C", nixdir, "restore", "dotfiles/"]);
      stowed = true;
    } else {
      console.log(`${c.yellow}Stow failed${c.reset}`);
    }
  } else {
    console.log(`${c.red}Build failed!${c.reset}`);
    if (committed) {
      console.log(`${c.yellow}Reverting commit (keeping files)...${c.reset}`);
      await run(["git", "-C", nixdir, "reset", "--soft", "HEAD~1"]);
    }
    process.exit(1);
  }

  // Report
  console.log("");
  console.log(`${c.bold}${c.cyan}Report${c.reset}`);
  console.log(committed ? `  ${c.green}✓${c.reset} Commit` : `  ${c.yellow}−${c.reset} Commit ${c.dim}(nothing to commit)${c.reset}`);
  console.log(built     ? `  ${c.green}✓${c.reset} Build`  : `  ${c.red}✗${c.reset} Build`);
  console.log(pushed    ? `  ${c.green}✓${c.reset} Push`   : `  ${c.red}✗${c.reset} Push`);
  console.log(stowed    ? `  ${c.green}✓${c.reset} Stow`   : `  ${c.red}✗${c.reset} Stow`);
  console.log("");
}

main();
