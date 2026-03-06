#!/usr/bin/env bun
// nixl - pretty-print NixOS generations

import { c, listGenerations } from "./lib";

async function main() {
  const gens = await listGenerations();

  console.log(
    `${c.blue}${c.bold}  ${"Gen".padEnd(4)}  ${"Date".padEnd(20)}  Description${c.reset}`,
  );

  for (const gen of gens.reverse()) {
    const marker = gen.current ? `${c.yellow}*${c.reset}` : " ";
    const genColor = gen.current ? `${c.yellow}${c.bold}` : "";
    const dateStr = `${gen.date} ${gen.time}`;

    console.log(
      `${marker} ${genColor}${gen.number.padEnd(4)}${c.reset}  ${c.cyan}${dateStr}${c.reset}  ${c.green}${gen.description}${c.reset}`,
    );
  }
}

main();
