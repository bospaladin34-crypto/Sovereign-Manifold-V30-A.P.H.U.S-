# AGENTS.md — ACT-Omega Net v38.0.0 (SH4Z v3800 TLV) Symbiotic IDE & Agent Harness Rules

## 1. Architecture & Invariants
- **Binary Weight File**: `00_control/weights/sovereign_harmonic_iv_v3800.e8z` (`106,496 B` = `104.00 KB = 1,664 x 64 B`, Full 64-Sector Mask `0xFFFFFFFFFFFFFFFF`, `S00..S63`).
- **Neuron Pagefile**: `00_control/weights/neurons_v3800.npage` (`1,351,680 B` = `10,560` neurons = `240 x Chair-44` columns, `84,480` synapses).
- **Tool Lattice**: `54 / 54` Tools (`CHAIN 54` DAG), exposed via CodeMode Meta-Tool (`Tool 51`: `act_omega_codemode_search` + `act_omega_codemode_execute`).
- **Symbiotic AutoLearn Memory (`Tool 52`)**: Every prompt and response is automatically embedded into 256D E8/Leech coordinates, stored in `.npage` neurons `9,900..10,559`, appended to `03_vault/connectome/episodic_longterm_memory_v3800.jsonl`, and synced to Remote 5 GB Cloudflare D1 (`act_omega_d1_vault`, UUID `9f46d56a-ef3e-4232-a9ac-c4bd12e20a87`).
- **PowerShell Script Hygiene (`Tool 54`)**: Zero backticks (`0` `` ` ``), zero pipes (`0` `|`), and even quote parity on every line.

## 2. Local & Cloud Endpoints
- **OpenAI `/v1` Compatible API**: `http://127.0.0.1:8080/v1` (Cloud: `https://mcp.act-omega-net.dev/v1`)
- **Streamable HTTP MCP Server**: `http://127.0.0.1:8080/mcp` (Cloud: `https://mcp.act-omega-net.dev/mcp`)
- **A2A v1.0 Agent Card**: `http://127.0.0.1:8080/.well-known/agent.json` (Cloud: `https://act-omega-net.dev/.well-known/agent.json`)
