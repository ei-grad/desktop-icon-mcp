const assert = require("assert");
const { PassThrough } = require("stream");
const { handleRequest, startServer } = require("./src/server.js");
const { createToolHandlers } = require("./src/tools.js");

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function waitForResponses(output, count) {
  return new Promise((resolve, reject) => {
    let buffer = "";
    const responses = [];
    const timer = setTimeout(() => reject(new Error(`Timed out waiting for ${count} responses`)), 5000);
    output.on("data", (chunk) => {
      buffer += chunk.toString("utf8");
      while (buffer.includes("\n")) {
        const index = buffer.indexOf("\n");
        const line = buffer.slice(0, index);
        buffer = buffer.slice(index + 1);
        if (line.trim()) responses.push(JSON.parse(line));
        if (responses.length === count) {
          clearTimeout(timer);
          resolve(responses);
        }
      }
    });
  });
}

async function main() {
  const tools = createToolHandlers({
    helper: async () => {
      throw new Error("helper should not be called by this smoke test");
    },
  });

  const init = await handleRequest({
    jsonrpc: "2.0",
    id: 1,
    method: "initialize",
    params: { protocolVersion: "2024-11-05" },
  }, tools);
  assert.strictEqual(init.result.serverInfo.name, "desktop-icon-mcp");

  const listed = await handleRequest({ jsonrpc: "2.0", id: 2, method: "tools/list" }, tools);
  const names = listed.result.tools.map((tool) => tool.name);
  for (const expected of [
    "list_desktop_icons",
    "describe_desktop_icon_grid",
    "diagnose_desktop_icon_host",
    "list_desktop_displays",
    "list_desktop_screenshot_formats",
    "capture_desktop_screenshot",
    "move_desktop_icon",
    "arrange_desktop_icons_grid",
    "plan_desktop_icon_layout",
    "plan_and_apply_desktop_icon_layout",
    "set_desktop_snap_to_grid",
    "save_desktop_icon_layout",
    "restore_desktop_icon_layout",
  ]) {
    assert(names.includes(expected), `missing tool ${expected}`);
  }

  const ignored = await handleRequest({ jsonrpc: "2.0", method: "notifications/cancelled" }, tools);
  assert.strictEqual(ignored, null);
  const listedNotification = await handleRequest({ jsonrpc: "2.0", method: "tools/list" }, tools);
  assert.strictEqual(listedNotification, null);

  const input = new PassThrough();
  const output = new PassThrough();
  let activeCalls = 0;
  let maxActiveCalls = 0;
  startServer({
    input,
    output,
    tools: {
      schemas: [],
      call: async () => {
        activeCalls++;
        maxActiveCalls = Math.max(maxActiveCalls, activeCalls);
        await delay(20);
        activeCalls--;
        return { ok: true };
      },
    },
  });
  const responsesPromise = waitForResponses(output, 2);
  input.write(`${JSON.stringify({ jsonrpc: "2.0", id: 3, method: "tools/call", params: { name: "slow", arguments: {} } })}\n`);
  input.write(`${JSON.stringify({ jsonrpc: "2.0", id: 4, method: "tools/call", params: { name: "slow", arguments: {} } })}\n`);
  input.end();
  const responses = await responsesPromise;
  assert.deepStrictEqual(responses.map((response) => response.id), [3, 4]);
  assert.strictEqual(maxActiveCalls, 1);

  console.log("ok JS MCP tools/list smoke test");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
