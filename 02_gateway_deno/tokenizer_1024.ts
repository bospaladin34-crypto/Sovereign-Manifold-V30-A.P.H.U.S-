// 02_gateway_l2/tokenizer_1024.ts
import { VOCAB_240 } from "./tokenizer_240.ts";

export const COMPOUND_TERMS: string[] = [
  "artin braid", "braid group", "sheaf cohomology", "hodge decomposition",
  "knot theory", "reidemeister move", "coboundary cancellation", "rebar memory",
  "cache coherence", "non-blocking queue", "atomic barrier", "zero-copy",
  "deno ffi", "c-abi bridge", "geomagnetic field", "flux density",
  "microseismic resonance", "carrier wave", "solar diurnal", "mantle conductivity",
  "hall effect", "categorical semiotics", "language manifold", "topological embedding",
  "semantic curvature", "information geometry", "autopoietic feedback", "operational closure",
  "straight-through estimator", "quantization-aware", "e8 polytope", "root lattice",
  "kahler manifold", "calabi-yau", "fubini-study", "dolbeault cohomology",
  "hard lefschetz", "kodaira embedding", "ricci flat", "plurisubharmonic",
  "symplectic structure", "complex structure", "mirror symmetry", "quantum invariant",
  "heegaard floer", "khovanov homology", "kirby calculus", "amari connection",
  "fisher information", "kolmogorov complexity", "dissipative structure", "self-organized criticality"
];

export const VOCAB_1024: string[] = [...VOCAB_240];
while (VOCAB_1024.length < 1024) {
  const nextIdx = VOCAB_1024.length;
  const compoundIdx = nextIdx - 240;
  if (compoundIdx < COMPOUND_TERMS.length) {
    VOCAB_1024.push(COMPOUND_TERMS[compoundIdx]);
  } else {
    const rootA = VOCAB_240[compoundIdx % 240] || "e";
    const rootB = VOCAB_240[(compoundIdx * 7) % 240] || "8";
    VOCAB_1024.push(`${rootA}_${rootB}`);
  }
}

export function tokenizeSubwords1024(text: string): number[] {
  const tokens: number[] = [];
  let i = 0;
  while (i < text.length) {
    let matched = false;
    for (let len = Math.min(32, text.length - i); len >= 2; len--) {
      const sub = text.slice(i, i + len).toLowerCase();
      const idx = VOCAB_1024.indexOf(sub);
      if (idx !== -1 && idx >= 240) {
        tokens.push(idx);
        i += len;
        matched = true;
        break;
      }
    }
    if (!matched) {
      for (let len = Math.min(8, text.length - i); len >= 1; len--) {
        const sub = text.slice(i, i + len).toLowerCase();
        const idx = VOCAB_1024.indexOf(sub);
        if (idx !== -1) {
          tokens.push(idx);
          i += len;
          matched = true;
          break;
        }
      }
    }
    if (!matched) i++;
  }
  return tokens;
}

export function detokenizeSubwords1024(tokens: number[]): string {
  return tokens.map(t => VOCAB_1024[t % 1024] || "").join("");
}