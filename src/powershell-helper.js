const { spawn } = require("child_process");
const path = require("path");

const DEFAULT_TIMEOUT_MS = 30000;

function defaultHelperPath() {
  return path.resolve(__dirname, "..", "scripts", "desktop_icon_helper.ps1");
}

function callPowerShellHelper(command, args = {}, options = {}) {
  const helperPath = options.helperPath || defaultHelperPath();
  const powershell = options.powershell || "powershell.exe";
  const timeoutMs = options.timeoutMs || DEFAULT_TIMEOUT_MS;
  const request = JSON.stringify({ command, args });

  return new Promise((resolve, reject) => {
    const child = spawn(
      powershell,
      ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", helperPath],
      { stdio: ["pipe", "pipe", "pipe"], windowsHide: true }
    );

    let stdout = "";
    let stderr = "";
    let settled = false;
    const timer = setTimeout(() => {
      settled = true;
      child.kill();
      reject(new Error(`PowerShell helper timed out after ${timeoutMs}ms while running ${command}`));
    }, timeoutMs);

    child.stdout.setEncoding("utf8");
    child.stderr.setEncoding("utf8");
    child.stdout.on("data", (chunk) => { stdout += chunk; });
    child.stderr.on("data", (chunk) => { stderr += chunk; });
    child.on("error", (error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      reject(error);
    });
    child.on("close", (code) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      if (code !== 0) {
        reject(new Error(`PowerShell helper exited with ${code}: ${stderr || stdout}`.trim()));
        return;
      }
      try {
        const payload = JSON.parse(stdout.replace(/^\uFEFF/, ""));
        if (!payload.ok) throw new Error(payload.error || `PowerShell helper command ${command} failed`);
        resolve(payload.result);
      } catch (error) {
        reject(new Error(`Invalid PowerShell helper response: ${error.message}; stdout=${stdout}; stderr=${stderr}`));
      }
    });

    child.stdin.end(request, "utf8");
  });
}

module.exports = { callPowerShellHelper, defaultHelperPath };
