import { isbot } from "https://cdn.jsdelivr.net/npm/isbot@latest/index.mjs";
import { TextLineStream } from "https://deno.land/std@0.221.0/streams/mod.ts";

// Does not work with masked IPs (e.g. anonip)
// const badIPsRespone = await fetch(
//   "https://github.com/LittleJake/ip-blacklist/blob/main/all_blacklist.txt",
// );
// if (!badIPsRespone.ok) {
//   throw new Error("Failed to download blacklist " + badIPsRespone.text());
// }
// const badIPs = (await badIPsRespone.text()).split("\n");

const lines = Deno.stdin.readable
  .pipeThrough(new TextDecoderStream())
  .pipeThrough(new TextLineStream());

for await (const line of lines) {
  
  // Works with Apache2 'Combined' log format
  const [ip, , , , , , , , , , , ...userAgentParts] = line.split(" ");
  const userAgent = userAgentParts.join(" ");

  const lineIsOk = !isbot(userAgent);
  // lineIsOk = !badIPs.includes(ip))

  if (lineIsOk) {
    console.log(line);
  }
}