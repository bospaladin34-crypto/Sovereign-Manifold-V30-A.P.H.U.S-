# 00_control\mcp_stdio_wrapper.ps1
# ACT-Omega Net v61.0.0 Model Context Protocol (MCP) Stdio JSON-RPC 2.0 Wrapper
# Connects stdio-based MCP clients (Claude Desktop, Zed, Cursor, Cline, Gemini) to :8097/mcp
# STRICT INVARIANT: All logging to stderr; stdout is reserved purely for clean JSON-RPC 2.0 lines.

param(
    [string]$Endpoint = "http://127.0.0.1:8097/mcp",
    [int]$TimeoutSec = 30
)

$ErrorActionPreference = "Continue"

# Configure console streams for UTF-8 without BOM
try {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# Load System.Net.Http for high-performance keep-alive connection
Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue

$httpClient = [System.Net.Http.HttpClient]::new()
$httpClient.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)

[Console]::Error.WriteLine("[mcp_stdio_wrapper] ACT-Omega v61.0.0 MCP Stdio Gateway online. Forwarding to $Endpoint")

while ($true) {
    $line = [Console]::In.ReadLine()
    if ($null -eq $line) {
        # End of input stream (stdin closed)
        break
    }

    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        continue
    }

    try {
        $content = [System.Net.Http.StringContent]::new($trimmed, [System.Text.Encoding]::UTF8, "application/json")
        $response = $httpClient.PostAsync($Endpoint, $content).GetAwaiter().GetResult()
        $respBody = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()

        # Output the single-line JSON response to stdout
        [Console]::Out.WriteLine($respBody)
    } catch {
        [Console]::Error.WriteLine("[mcp_stdio_wrapper] Error forwarding request: $($_.Exception.Message)")
        # Return fallback JSON-RPC error so client does not hang
        $errJson = '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"Failed to communicate with local MCP server at ' + $Endpoint + ': ' + $_.Exception.Message.Replace('"', '\"') + '"}}'
        [Console]::Out.WriteLine($errJson)
    }
}
