#!/usr/bin/env bun
// nixl - pretty-print NixOS generations

import { c, listGenerations } from "./lib";

async function main() {
  const gens = await listGenerations();
  const genWidth = Math.max(3, ...gens.map((g) => g.number.length));

  console.log(
    `${c.blue}${c.bold}  ${"Gen".padEnd(genWidth)}  ${"Date".padEnd(19)}  Description${c.reset}`,
  );

  for (const gen of gens.reverse()) {
    const marker = gen.current ? `${c.yellow}*${c.reset}` : " ";
    const genColor = gen.current ? `${c.yellow}${c.bold}` : "";
    const dateStr = `${gen.date} ${gen.time}`;

    console.log(
      `${marker} ${genColor}${gen.number.padEnd(genWidth)}${c.reset}  ${c.cyan}${dateStr}${c.reset}  ${c.green}${gen.description}${c.reset}`,
    );
  }
}

main();
