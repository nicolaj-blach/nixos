// Shared utilities for nix scripts

import { $ } from "bun";

// ANSI colors
export const c = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
} as const;

export const nixdir = `${Bun.env.HOME}/nixos`;

// NixOS generation parsing

export type Generation = {
  number: string;
  date: string;
  time: string;
  description: string;
  current: boolean;
};

export function parseGenerations(output: string): Generation[] {
  const lines = output.split("\n").filter((l) => l.trim().length > 0);
  return lines.slice(1).map((line) => {
    const fields = line.trim().split(/\s+/);
    return {
      number: fields[0],
      date: fields[1],
      time: fields[2],
      description: fields[3]?.replace(/_/g, " ") ?? "",
      current: fields.at(-1) === "True",
    };
  });
}

export async function listGenerations(): Promise<Generation[]> {
  const output = await $`nixos-rebuild list-generations 2>/dev/null`
    .text()
    .catch(() => "");
  if (!output.trim()) {
    console.error("Failed to list generations");
    process.exit(1);
  }
  return parseGenerations(output);
}
