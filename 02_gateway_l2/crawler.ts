import { crypto } from "https://deno.land/std@0.224.0/crypto/mod.ts";
import { encodeHex } from "https://deno.land/std@0.224.0/encoding/hex.ts";

export interface CrawlSource {
  domain: string;
  url: string;
  curriculum: string;
}

export interface CrawlerStatus {
  active: boolean;
  interval_ms: number;
  total_crawls: number;
  total_shards_emitted: number;
  total_tokens_harvested: number;
  last_crawl_ts: string | null;
  last_error: string | null;
}

export class ContinuousCrawler {
  private shardsDir: string;
  private intervalMs: number;
  private timerId: number | null = null;
  private isCrawling: boolean = false;
  private status: CrawlerStatus;

  private sources: CrawlSource[] = [
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Braid_group" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Sheaf_(mathematics)" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Non-blocking_algorithm" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Cache_coherence" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Earth%27s_magnetic_field" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Microseism" },
    { domain: "epistemology", curriculum: "curriculum_d", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Epistemology" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Phenomenology_(philosophy)" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Hodge_theory" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Memory_barrier" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Geomagnetic_reversal" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Dialectic" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Algebraic_topology" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Translation_lookaside_buffer" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Schumann_resonances" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Hermeneutics" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Lie_algebra" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Differential_geometry" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Clifford_algebra" },
    { domain: "topology", curriculum: "curriculum_a", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Fiber_bundle" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Asynchronous_I/O" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Non-uniform_memory_access" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Inter-process_communication" },
    { domain: "systems", curriculum: "curriculum_b", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Instruction_set_architecture" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Dynamo_theory" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Magnetohydrodynamics" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Paleomagnetism" },
    { domain: "geophysics", curriculum: "curriculum_c", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Plate_tectonics" },
    { domain: "epistemology", curriculum: "curriculum_d", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Category_theory" },
    { domain: "epistemology", curriculum: "curriculum_d", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Model_theory" },
    { domain: "epistemology", curriculum: "curriculum_d", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Modal_logic" },
    { domain: "epistemology", curriculum: "curriculum_d", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Semiotics" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Ontology" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Cybernetics" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Dialectical_materialism" },
    { domain: "philosophy", curriculum: "curriculum_e", url: "https://en.wikipedia.org/api/rest_v1/page/summary/Mereology" },
  ];

  constructor(shardsDir: string = "../04_canonical_vault/shards", intervalMinutes: number = 5) {
    this.shardsDir = shardsDir;
    this.intervalMs = intervalMinutes * 60 * 1000;
    this.status = {
      active: false,
      interval_ms: this.intervalMs,
      total_crawls: 0,
      total_shards_emitted: 0,
      total_tokens_harvested: 0,
      last_crawl_ts: null,
      last_error: null,
    };
  }

  public getStatus(): CrawlerStatus {
    return { ...this.status };
  }

  public start(): void {
    if (this.timerId !== null) return;
    this.status.active = true;
    console.log(`[Crawler] Continuous background crawler active (${this.intervalMs / 1000}s interval)`);
    this.crawlCycle();
    this.timerId = setInterval(() => this.crawlCycle(), this.intervalMs);
  }

  public stop(): void {
    if (this.timerId !== null) {
      clearInterval(this.timerId);
      this.timerId = null;
    }
    this.status.active = false;
    console.log("[Crawler] Continuous background crawler stopped");
  }

  public async triggerNow(): Promise<number> {
    return await this.crawlCycle();
  }

  private sanitizeText(raw: string): string {
    return raw
      .replace(/<[^>]*>/g, " ")
      .replace(/\[\d+\]/g, " ")
      .replace(/\s+/g, " ")
      .trim();
  }

  private tokenizeToZ64(text: string): Uint8Array {
    const encoder = new TextEncoder();
    const rawBytes = encoder.encode(text);
    const tokens = new Uint8Array(rawBytes.length);
    for (let i = 0; i < rawBytes.length; i++) {
      tokens[i] = rawBytes[i] % 64;
    }
    return tokens;
  }

  private async buildBinshard(tokens: Uint8Array): Promise<Uint8Array> {
    const headerSize = 64;
    const fileBytes = new Uint8Array(headerSize + tokens.length);

    const magicStr = "ACT_OMEGA_BINSHARD_V30\0";
    fileBytes.set(new TextEncoder().encode(magicStr), 0);

    const digestBuffer = await crypto.subtle.digest("SHA-256", tokens);
    fileBytes.set(new Uint8Array(digestBuffer), 24);

    const view = new DataView(fileBytes.buffer);
    view.setBigUint64(56, BigInt(tokens.length), true);

    fileBytes.set(tokens, 64);
    return fileBytes;
  }

  public async crawlCycle(): Promise<number> {
    if (this.isCrawling) return 0;
    this.isCrawling = true;
    let newTokens = 0;

    try {
      await Deno.mkdir(this.shardsDir, { recursive: true });

      for (const src of this.sources) {
        if (!src || !src.url) continue;
        try {
          const resp = await fetch(src.url, {
            headers: { "User-Agent": "ACT-Omega-Sovereign-Crawler/30.0 (Research Archive Ingest)" },
          });
          if (!resp.ok) continue;

          const json = await resp.json();
          const cleanText = this.sanitizeText(json.extract || json.title || "");
          if (cleanText.length < 50) continue;

          const tokens = this.tokenizeToZ64(cleanText);
          const binshardBytes = await this.buildBinshard(tokens);

          const digestBuffer = await crypto.subtle.digest("SHA-256", tokens);
          const hashHex = encodeHex(new Uint8Array(digestBuffer)).slice(0, 16);
          const fileName = `${src.curriculum}_${hashHex}.binshard`;
          const filePath = `${this.shardsDir}/${fileName}`;

          try {
            await Deno.stat(filePath);
          } catch {
            await Deno.writeFile(filePath, binshardBytes);
            newTokens += tokens.length;
            this.status.total_shards_emitted++;
            console.log(`[Crawler] Emitted ${fileName} (${tokens.length} tokens, ${binshardBytes.length} bytes)`);
          }
        } catch (srcErr) {
          console.warn(`[Crawler] Source error (${src.url}):`, (srcErr as Error).message);
        }

        await new Promise((r) => setTimeout(r, 600));
      }

      this.status.total_crawls++;
      this.status.total_tokens_harvested += newTokens;

      if (newTokens > 0) {
        console.log(`[Crawler] ${newTokens} new tokens harvested across new shards. Auto-triggering background QAT...`);
        try {
          const cmd = new Deno.Command("C:\\sovereign_manifold_v30\\01_l0_core\\target\\release\\test_shard_training.exe", {
            args: [],
            stdout: "inherit",
            stderr: "inherit",
          });
          const child = cmd.spawn();
          child.status.then(async (status) => {
            if (status.success) {
              console.log("[Crawler] Background QAT training converged. Hot-reloading live gateway manifold...");
              try {
                const res = await fetch("http://127.0.0.1:8099/api/v1/harmonic/reload", { method: "POST" });
                const json = await res.json();
                console.log("[Crawler] Manifold reload response:", json.status);
              } catch (err) {
                console.warn("[Crawler] Gateway reload notification warning:", (err as Error).message);
              }
            } else {
              console.warn(`[Crawler] Background QAT process exited with code ${status.code}`);
            }
          });
        } catch (e) {
          console.error("[Crawler] Failed to spawn background QAT:", (e as Error).message);
        }
      }

      this.status.last_crawl_ts = new Date().toISOString();
      this.status.last_error = null;
    } catch (err) {
      this.status.last_error = (err as Error).message;
      console.error("[Crawler] Crawl cycle error:", err);
    } finally {
      this.isCrawling = false;
    }

    return newTokens;
  }
}

// Standalone execution entrypoint
if (import.meta.main) {
  const crawler = new ContinuousCrawler("../04_canonical_vault/shards", 5);
  crawler.start();
}