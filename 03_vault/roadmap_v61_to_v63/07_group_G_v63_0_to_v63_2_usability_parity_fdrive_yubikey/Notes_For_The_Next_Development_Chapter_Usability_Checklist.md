Usability is where the clean kernel has to survive contact with real users. Here's a planning checklist built around that:

1\. Capability proof (does it still think?)  
\[ \] Frozen weight parity test: Same prompts through stock Gemma 4 vs your 6GB packed version, log diff in outputs  
\[ \] Perplexity baseline: Fixed corpus, report perplexity before/after E8/Leech quantization  
\[ \] Task evals: Pick 2 small ones to start, e.g. GSM8K sample and MMLU sample, not full suites yet  
\[ \] Define your win metric: Bytes per useful token, not just tokens/sec. That's your edge vs Nemotron

2\. Transformer highway (can it drive?)  
\[ \] KV cache design: Where does KV live in 7777D? Size, eviction, determinism rules  
\[ \] Attention integration: Document how attention scores map through CRT/Good-Thomas path  
\[ \] Decoding path: Greedy first, then decide if you need speculative/paged attention  
\[ \] TTFT / throughput harness: Time to first token \+ sustained tokens/sec on your actual 6GB card

3\. Adaptation (is it frozen forever?)  
\[ \] Fine-tune decision: Do you need gradient flow through trits, or is frozen inference \+ adapters enough?  
\[ \] Adapter story: If frozen, where do LoRA-style adapters attach without breaking bit-exactness?  
\[ \] Data in/out: How does new knowledge enter the mesh without a full rebuild?

4\. Distributed Vesper (do clones stay honest?)  
\[ \] Divergence detection: SHA-256 already does this, define the alert threshold  
\[ \] Healing protocol: When a node drifts by 1 trit, does it resync, reboot, or get quarantined?  
\[ \] Message layer: What actually goes over Cloudflare Workers/R2 vs local mesh? Size limits?  
\[ \] Clocking: Lock your 15.965Hz tick across nodes, define allowed jitter

5\. Developer usability (can anyone else use it?)  
\[ \] Python shim (untrusted): Thin FFI outside the hot path for HuggingFace/vLLM style calls, never inside kernel  
\[ \] .o7777 spec doc: One page: file format, versioning, how to load/inspect  
\[ \] Minimal SDK: "Run this and you're a node" \- what are the 3 commands?  
\[ \] Error messages: When Lean proof and Rust runtime disagree, what does the user see?

6\. Polyglot survival (can you maintain it?)  
\[ \] Source of truth: Pick one, likely Lean, and make Rust/Zig checked against it in CI  
\[ \] Reproducible build: One script builds all six languages, with SBOM  
\[ \] Bus factor doc: If you disappear for a month, what breaks first? Write it down

7\. Trust and ops  
\[ \] Hardware root of trust: Where does YubiKey attestation plug in?  
\[ \] Cold boot story: From power off to first token, what are the steps?  
\[ \] Observability: What 5 numbers do you need on the dashboard to know the mesh is healthy?

Start with section 1\. You can't plan usability until you can say "yes, it still thinks after packing" with numbers. Everything else gets easier once you have that.