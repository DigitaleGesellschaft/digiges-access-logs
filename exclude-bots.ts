import isBot from 'https://cdn.jsdelivr.net/npm/isbot@latest/index.mjs';


// Does not work with masked IPs (e.g. anonip)
// const badIPsRespone = await fetch(
//   "https://github.com/LittleJake/ip-blacklist/blob/main/all_blacklist.txt",
// );
// if (!badIPsRespone.ok) {
//   throw new Error("Failed to download blacklist " + badIPsRespone.text());
// }
// const badIPs = (await badIPsRespone.text()).split("\n");


const decoder = new TextDecoder();
for await (const chunk of Deno.stdin.readable) {
  const text = decoder.decode(chunk);
  const lines = text.split("\n");
  for (const line of lines) {
    let lineIsOk = true;

    // Works with Apache2 'Combined' log format
    const [ip, , , , , , , , , , , ...userAgentParts] = line.split(' ');
    const userAgent = userAgentParts.join(' ');
    // @ts-ignore
    lineIsOk = !isBot(userAgent)

    // lineIsOk = !badIPs.includes(ip))
    
    if(lineIsOk){
      console.log(line);
    }
  }
}
