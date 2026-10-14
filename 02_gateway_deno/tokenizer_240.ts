// 02_gateway_l2/tokenizer_240.ts
// ACT-Omega v31.0: 240-Token Subword Tokenizer, Semantic Root Bridge & Morphological Stitcher
// Mapped 1:1 to the 240 Gosset E8 Root Vectors

export const VOCAB_240: string[] = [
  // 0..63: 64 Base Characters (Backward compatible)
  " ", "a", "b", "c", "d", "e", "f", "g", "h", "i",
  "j", "k", "l", "m", "n", "o", "p", "q", "r", "s",
  "t", "u", "v", "w", "x", "y", "z",
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
  "-", ".", ",", ":", ";", "!", "?", "'", "\"", "/",
  "\\", "(", ")", "[", "]", "{", "}", "@", "#", "$",
  "%", "^", "&", "*", "+", "=", "_",
  // 64..133: Top English Bigrams / Morphological Units (70)
  "th", "he", "in", "er", "an", "re", "on", "at", "en", "nd",
  "ti", "es", "or", "te", "of", "ed", "is", "it", "al", "ar",
  "st", "to", "nt", "ou", "se", "ha", "le", "ve", "co", "me",
  "de", "hi", "ri", "ro", "ic", "ne", "ea", "ra", "ce", "li",
  "ch", "ll", "be", "ma", "si", "om", "ur", "ca", "el", "ta",
  "la", "ns", "ge", "ly", "pe", "wa", "ec", "pr", "no", "di",
  "us", "il", "ac", "as", "lo", "mo", "so", "we", "ad", "un",
  // 134..181: Top English Trigrams & Core Function Words (48)
  "the", "and", "ing", "ion", "tio", "ent", "ati", "for", "her", "ter",
  "hat", "tha", "ere", "ate", "his", "con", "res", "ver", "all", "ons",
  "nce", "men", "ith", "tes", "int", "com", "per", "pro", "out", "str",
  "ble", "ive", "not", "one", "you", "are", "was", "wit", "can", "has",
  "but", "had", "our", "more", "when", "from", "this", "that",
  // 182..239: Topological, Systems & ACT-Omega Vocabulary (58)
  "act", "omega", "e8", "braid", "topo", "logic", "norm", "rad", "gate", "way",
  "stalk", "flow", "knot", "loop", "step", "layer", "phase", "lock", "wave", "spin",
  "field", "geom", "root", "poly", "tope", "sheaf", "tor", "h1", "loss", "eval",
  "load", "tok", "sec", "hz", "rebar", "host", "link", "mesh", "node", "core",
  "ring", "fast", "pure", "true", "data", "hash", "sync", "vault", "shard", "batch",
  "train", "infer", "quant", "state", "cell", "unit", "head", "self"
];

export const VOCAB_INDEX_MAP: Record<string, number> = Object.fromEntries(
  VOCAB_240.map((w, i) => [w, i])
);

const SORTED_ITEMS = VOCAB_240.map((str, idx) => ({ str, idx }))
  .sort((a, b) => b.str.length - a.str.length);

// Valid standalone free morphemes (excludes raw characters 0..63 and bound syllable fragments)
const FREE_WORDS_LIST = [
  "in", "on", "at", "or", "of", "is", "it", "to", "be", "as", "so", "we",
  "the", "and", "for", "all", "out", "not", "one", "you", "are", "was", "can", "has",
  "but", "had", "our", "more", "when", "from", "this", "that",
  "act", "omega", "e8", "braid", "topo", "logic", "norm", "rad", "gate", "way",
  "stalk", "flow", "knot", "loop", "step", "layer", "phase", "lock", "wave", "spin",
  "field", "geom", "root", "poly", "tope", "sheaf", "tor", "h1", "loss", "eval",
  "load", "tok", "sec", "hz", "rebar", "host", "link", "mesh", "node", "core",
  "ring", "fast", "pure", "true", "data", "hash", "sync", "vault", "shard", "batch",
  "train", "infer", "quant", "state", "cell", "unit", "head", "self"
];

export const FREE_WORD_SET: Set<number> = new Set(
  FREE_WORDS_LIST.map((w) => VOCAB_INDEX_MAP[w]).filter((idx) => idx !== undefined && idx < 236)
);

// 7-Slot SVO Grammatical Cadence Sets
export const SVO_SLOT_SETS: Set<number>[] = [
  new Set(["the", "our", "this", "all"].map((w) => VOCAB_INDEX_MAP[w])),
  new Set(["pure", "true", "fast", "topo", "geom", "quant", "e8", "rebar", "act"].map((w) => VOCAB_INDEX_MAP[w])),
  new Set(["sheaf", "stalk", "mesh", "node", "core", "ring", "wave", "phase", "field", "root", "poly", "vault", "shard", "batch", "host", "braid", "layer"].map((w) => VOCAB_INDEX_MAP[w])),
  new Set(["sync", "lock", "flow", "link", "eval", "infer", "train", "load", "spin"].map((w) => VOCAB_INDEX_MAP[w])),
  new Set(["in", "on", "to", "for", "from", "at", "as"].map((w) => VOCAB_INDEX_MAP[w])),
  new Set(["the", "our", "this", "pure", "true", "quant", "topo", "geom", "e8", "h1"].map((w) => VOCAB_INDEX_MAP[w])),
  new Set(["norm", "hz", "phase", "mesh", "ring", "vault", "core", "root", "sec", "tok", "tope", "logic", "way", "gate", "layer", "braid", "stalk"].map((w) => VOCAB_INDEX_MAP[w]))
];

const SEMANTIC_CONCEPT_BRIDGE: Record<string, string[]> = {
  sovereign: ["act", "omega", "pure", "self", "state"],
  manifold: ["poly", "tope", "sheaf", "field", "geom", "state"],
  converges: ["sync", "lock", "flow", "phase", "norm", "h1"],
  laminar: ["flow", "pure", "wave", "phase", "lock"],
  equilibrium: ["norm", "lock", "state", "true", "h1", "hz"],
  workstation: ["host", "core", "rebar", "ring", "node"],
  distributes: ["flow", "link", "mesh", "sync", "load"],
  quantized: ["quant", "e8", "root", "norm"],
  weight: ["data", "batch", "shard", "vault", "layer"],
  deltas: ["step", "batch", "sync", "train", "loss"],
  edge: ["node", "mesh", "link", "fast"],
  transmits: ["link", "flow", "wave", "sync", "hz"],
  gradient: ["train", "loss", "step", "flow", "quant"],
  swarm: ["mesh", "node", "sync", "host", "link"],
  aggregator: ["host", "core", "vault", "sync", "state"],
  tri: ["mesh", "node", "core", "link", "sync"],
  silicon: ["core", "node", "rebar", "fast"],
  cluster: ["mesh", "host", "node", "link", "sync"],
  unifies: ["sync", "link", "lock", "braid", "true"],
  intel: ["host", "core", "rebar", "fast"],
  tensor: ["node", "quant", "e8", "core", "fast"],
  architectures: ["layer", "ring", "mesh", "core", "geom"],
  latency: ["fast", "sec", "tok", "hz", "pure"],
  calibrate: ["eval", "norm", "lock", "sync", "phase"],
  projection: ["geom", "root", "e8", "poly", "tope"],
  matrix: ["layer", "field", "root", "e8"],
  preserve: ["lock", "true", "norm", "vault", "state"],
  topological: ["topo", "logic", "braid", "sheaf", "knot"],
  invariants: ["true", "norm", "h1", "lock", "state"],
  observer: ["self", "head", "node", "phase", "eval"],
  maintains: ["lock", "sync", "flow", "state", "true"],
  carrier: ["wave", "hz", "phase", "rad", "lock"],
  clock: ["hz", "sec", "phase", "lock", "sync"],
  local: ["node", "mesh", "host", "ring"]
};

export function tokenizeSubwords240(text: string): number[] {
  const lower = text.toLowerCase();
  const tokens: number[] = [];
  let cursor = 0;

  while (cursor < lower.length) {
    let matched = false;
    const remaining = lower.slice(cursor);
    for (const item of SORTED_ITEMS) {
      if (remaining.startsWith(item.str)) {
        tokens.push(item.idx);
        cursor += item.str.length;
        matched = true;
        break;
      }
    }
    if (!matched) {
      tokens.push(0);
      cursor += 1;
    }
  }
  return tokens;
}

export function extractSemanticPromptRoots(prompt: string): number[] {
  const rawWords = prompt.toLowerCase().replace(/[^a-z0-9\s-]/g, " ").split(/\s+/).filter(Boolean);
  const roots: number[] = [];
  for (const w of rawWords) {
    const directIdx = VOCAB_INDEX_MAP[w];
    if (directIdx !== undefined && FREE_WORD_SET.has(directIdx)) {
      roots.push(directIdx);
    }
    const mapped = SEMANTIC_CONCEPT_BRIDGE[w];
    if (mapped) {
      for (const target of mapped) {
        const tIdx = VOCAB_INDEX_MAP[target];
        if (tIdx !== undefined && tIdx < 236) {
          roots.push(tIdx);
        }
      }
    }
  }
  if (roots.length === 0) {
    for (const t of tokenizeSubwords240(prompt)) {
      if (FREE_WORD_SET.has(t)) roots.push(t);
    }
  }
  return roots;
}

export function recombineAndStitchSubwords(tokens: number[]): { words: string[]; text: string } {
  const raw = tokens
    .filter((t) => t >= 0 && t < VOCAB_240.length)
    .map((t) => VOCAB_240[t].trim())
    .filter((s) => s.length > 0);

  const VERBS_SING: Record<string, string> = {
    sync: "synchronizes",
    lock: "locks",
    flow: "flows",
    link: "links",
    eval: "evaluates",
    infer: "infers",
    train: "trains",
    load: "loads",
    spin: "spins"
  };
  const VERBS_PLUR: Record<string, string> = {
    sync: "synchronize",
    lock: "lock",
    flow: "flow",
    link: "link",
    eval: "evaluate",
    infer: "infer",
    train: "train",
    load: "load",
    spin: "spin"
  };
  const NOUN_EXPAND: Record<string, string> = {
    e8: "E8",
    h1: "H1",
    hz: "15.0 Hz",
    rebar: "ReBAR",
    geom: "geometric",
    quant: "quantized",
    topo: "topological",
    poly: "polytope",
    tope: "manifold",
    tok: "tokens",
    sec: "section",
    rad: "radians",
    tor: "torsion",
    norm: "unitary norm",
    act: "ACT-Omega"
  };
  const PLURAL_NOUNS: Record<string, string> = {
    node: "nodes",
    core: "cores",
    shard: "shards",
    stalk: "stalks",
    layer: "layers",
    root: "roots",
    wave: "waves",
    ring: "rings",
    state: "states",
    host: "hosts",
    vault: "vaults",
    batch: "batches",
    sheaf: "sheaves",
    braid: "braids",
    mesh: "meshes",
    field: "fields",
    poly: "polytopes"
  };

  const words: string[] = [];
  let clauseIsPlural = false;

  for (let i = 0; i < raw.length; i++) {
    const w = raw[i];
    const slot = i % 7;
    if (slot === 0) {
      clauseIsPlural = (w === "all" || w === "we" || w === "you");
    }
    let rendered = NOUN_EXPAND[w] || w;
    if (slot === 3 && VERBS_SING[w]) {
      rendered = clauseIsPlural ? VERBS_PLUR[w] : VERBS_SING[w];
    } else if (slot === 2 && clauseIsPlural && PLURAL_NOUNS[w]) {
      rendered = PLURAL_NOUNS[w];
    }
    if (slot === 6 && i + 1 < raw.length) {
      rendered = rendered + ";";
    }
    words.push(rendered);
  }

  let text = words.join(" ").replace(/\s+([.,!?;:])/g, "$1");
  if (text.length > 0) {
    text = text.charAt(0).toUpperCase() + text.slice(1) + ".";
  }
  return { words, text };
}

export function detokenizeSubwords240(tokens: number[]): string {
  return recombineAndStitchSubwords(tokens).text;
}