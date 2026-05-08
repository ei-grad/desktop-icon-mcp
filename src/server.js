const readline = require("readline");
const { createToolHandlers } = require("./tools.js");

function rpcResult(id, result) {
  return { jsonrpc: "2.0", id, result };
}

function rpcError(id, code, message) {
  return { jsonrpc: "2.0", id, error: { code, message } };
}

function toolContent(data) {
  return {
    content: [
      {
        type: "text",
        text: JSON.stringify(data, null, 2),
      },
    ],
  };
}

async function handleRequest(request, tools) {
  const hasId = Object.prototype.hasOwnProperty.call(request, "id");
  const id = hasId ? request.id : null;
  try {
    switch (request.method) {
      case "initialize":
        if (!hasId) return null;
        return rpcResult(id, {
          protocolVersion: request.params?.protocolVersion || "2024-11-05",
          capabilities: { tools: {} },
          serverInfo: { name: "desktop-icon-mcp", version: "0.1.0" },
        });
      case "notifications/initialized":
        return null;
      case "tools/list":
        if (!hasId) return null;
        return rpcResult(id, { tools: tools.schemas });
      case "tools/call": {
        const result = await tools.call(request.params?.name, request.params?.arguments || {});
        if (!hasId) return null;
        return rpcResult(id, toolContent(result));
      }
      default:
        if (!hasId) return null;
        return rpcError(id, -32601, `Unknown method: ${request.method}`);
    }
  } catch (error) {
    if (!hasId) return null;
    return rpcError(id, -32603, error.message || String(error));
  }
}

function startServer(options = {}) {
  const tools = options.tools || createToolHandlers(options);
  const input = options.input || process.stdin;
  const output = options.output || process.stdout;
  const rl = readline.createInterface({ input, crlfDelay: Infinity });
  let queue = Promise.resolve();

  async function processLine(line) {
    if (!line.trim()) return;
    let response;
    try {
      response = await handleRequest(JSON.parse(line), tools);
    } catch (error) {
      response = rpcError(null, -32700, error.message || String(error));
    }
    if (response) output.write(`${JSON.stringify(response)}\n`);
  }

  rl.on("line", (line) => {
    queue = queue
      .then(() => processLine(line))
      .catch((error) => {
        output.write(`${JSON.stringify(rpcError(null, -32603, error.message || String(error)))}\n`);
      });
  });

  return rl;
}

module.exports = { startServer, handleRequest, toolContent };
