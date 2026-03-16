#!/usr/bin/env bun
// ns - nix shell with auto-prefixing
// Sets IN_NIX_SHELL so starship detects the environment
// Accumulates packages across invocations in the same shell

const args = process.argv.slice(2);

if (args.length === 0) {
  console.error("Usage: ns <packages...>");
  console.error("Example: ns cowsay figlet lolcat");
  console.error("Example: ns nixpkgs#cowsay someFlake#somePackage");
  process.exit(1);
}

const defaultFlake = Bun.env.NIX_SHELL_FLAKE || "nixpkgs";
const existingPkgs = Bun.env.NS_PACKAGES || "";

// Accumulate packages
const allPkgs = existingPkgs
  ? [...existingPkgs.split(","), ...args]
  : args;

const pkgsName = allPkgs.join(", ");

// Process each package: if it contains '#', use as-is; otherwise prefix with default flake
const prefixedArgs = allPkgs.map((pkg) => {
  const trimmed = pkg.trim();
  return trimmed.includes("#") ? trimmed : `${defaultFlake}#${trimmed}`;
});

const proc = Bun.spawn(["nix", "shell", ...prefixedArgs], {
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
  env: {
    ...Bun.env,
    IN_NIX_SHELL: "impure",
    name: pkgsName,
    NS_PACKAGES: allPkgs.join(","),
  },
});

const exitCode = await proc.exited;
process.exit(exitCode);
