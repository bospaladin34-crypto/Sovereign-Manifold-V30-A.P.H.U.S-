//! 240-Token Conversational Byte-Pair Encoding (BPE) & Morphological SVO Dictionary
//! Bijectively mapped to the 240 Gosset E8 root vectors.
//! Includes special conversational control delimiters:
//! - 236: <|pad|>
//! - 237: <|prompt|>
//! - 238: <|response|>
//! - 239: <|eos|>

use crate::e8_roots::E8_ROOT_COUNT;

pub const VOCAB_SIZE_CONV: usize = E8_ROOT_COUNT; // 240

pub const TOKEN_PAD: usize = 236;
pub const TOKEN_PROMPT: usize = 237;
pub const TOKEN_RESPONSE: usize = 238;
pub const TOKEN_EOS: usize = 239;

pub static VOCAB_CONV: [&str; VOCAB_SIZE_CONV] = [
    // 0..63: 64 Base Characters (ASCII printable)
    " ", "a", "b", "c", "d", "e", "f", "g", "h", "i",
    "j", "k", "l", "m", "n", "o", "p", "q", "r", "s",
    "t", "u", "v", "w", "x", "y", "z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    ".", ",", "-", "_", ":", ";", "!", "?", "'", "\"", "/",
    "\\", "(", ")", "[", "]", "{", "}", "@", "#", "$",
    "%", "^", "&", "*", "+", "=",
    // 64..133: Top 70 English Bigrams & Morphological Units
    "th", "he", "in", "er", "an", "re", "on", "at", "en", "nd",
    "ti", "es", "or", "te", "of", "ed", "is", "it", "al", "ar",
    "st", "to", "nt", "ou", "se", "ha", "le", "ve", "co", "me",
    "de", "hi", "ri", "ro", "ic", "ne", "ea", "ra", "ce", "li",
    "ch", "ll", "be", "ma", "si", "om", "ur", "ca", "el", "ta",
    "la", "ns", "ge", "ly", "pe", "wa", "ec", "pr", "no", "di",
    "us", "il", "ac", "as", "lo", "mo", "so", "we", "ad", "un",
    // 134..185: Top 52 English Trigrams & Syntactic Connectives
    "the", "and", "ing", "ion", "tio", "ent", "ati", "for", "her", "ter",
    "hat", "tha", "ere", "ate", "his", "con", "res", "ver", "all", "ons",
    "nce", "men", "ith", "tes", "int", "com", "per", "pro", "out", "str",
    "ble", "ive", "not", "one", "you", "are", "was", "wit", "can", "has",
    "but", "had", "our", "more", "when", "from", "this", "that", "with", "what",
    "how", "why",
    // 186..235: 50 Core Domain / Semantic Scientific Words
    "act", "omega", "e8", "braid", "topo", "logic", "norm", "rad", "gate", "way",
    "stalk", "flow", "knot", "loop", "step", "layer", "phase", "lock", "wave", "spin",
    "field", "geom", "root", "poly", "tope", "sheaf", "tor", "h1", "loss", "eval",
    "load", "tok", "sec", "hz", "rebar", "host", "link", "mesh", "node", "core",
    "ring", "fast", "pure", "true", "data", "hash", "sync", "vault", "shard", "batch",
    // 236..239: 4 Reserved Conversational Delimiters
    "<|pad|>", "<|prompt|>", "<|response|>", "<|eos|>",
];

/// Complete set of standalone lexical words in VOCAB_CONV (excludes bound 1..3 char syllable fragments)
pub static FREE_WORD_INDICES: [usize; 102] = [
    67, 70, 72, 73, 74, 77, 78, 86, 89, 98, 102, 113, 121, 124, 126, 128, 129, 130, 131,
    134, 135, 140, 141, 146, 148, 152, 156, 157, 158, 162, 165, 166, 167, 168, 169, 170,
    171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185,
    186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202,
    203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219,
    220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 1,
];

// 7-Slot SVO Grammatical Cadence Sets matching 02_gateway_l2/tokenizer_240.ts
static SVO_SLOT_0_SUBJECT: [usize; 15] = [223, 224, 225, 211, 200, 198, 194, 234, 233, 188, 196, 191, 226, 206, 131];
static SVO_SLOT_1_MODIFIER: [usize; 7] = [227, 228, 229, 207, 189, 201, 209];
static SVO_SLOT_2_HEAD: [usize; 11] = [225, 226, 223, 224, 211, 234, 233, 206, 200, 194, 196];
static SVO_SLOT_3_VERB: [usize; 10] = [202, 232, 216, 195, 215, 186, 222, 169, 172, 173];
static SVO_SLOT_4_QUALIFIER: [usize; 10] = [207, 209, 228, 227, 201, 189, 134, 152, 181, 177];
static SVO_SLOT_5_OBJECT: [usize; 14] = [233, 234, 235, 211, 223, 225, 226, 206, 200, 210, 219, 230, 231, 214];
static SVO_SLOT_6_ANCHOR: [usize; 13] = [219, 192, 193, 218, 220, 217, 233, 234, 225, 183, 135, 175, 70];

/// Checks whether a token index corresponds to a standalone free word
pub fn is_free_word_token(id: usize) -> bool {
    FREE_WORD_INDICES.iter().any(|&x| x == id)
}

/// Returns the candidate token indices for a given 7-slot SVO grammatical position
pub fn svo_slot_candidates(slot: usize) -> &'static [usize] {
    match slot % 7 {
        0 => &SVO_SLOT_0_SUBJECT,
        1 => &SVO_SLOT_1_MODIFIER,
        2 => &SVO_SLOT_2_HEAD,
        3 => &SVO_SLOT_3_VERB,
        4 => &SVO_SLOT_4_QUALIFIER,
        5 => &SVO_SLOT_5_OBJECT,
        _ => &SVO_SLOT_6_ANCHOR,
    }
}

/// Formats a clean conversational instruction pair
pub fn format_instruction_pair(prompt: &str, response: &str) -> String {
    format!("<|prompt|> {} <|response|> {} <|eos|>", prompt.trim(), response.trim())
}

/// Greedy maximum-munch BPE tokenizer with special token detection
pub fn tokenize_conversational(text: &str) -> Vec<usize> {
    let lower = text.to_lowercase();
    let bytes = lower.as_bytes();
    let mut tokens = Vec::new();
    let mut cursor = 0;

    let mut sorted_indices: Vec<usize> = (0..VOCAB_SIZE_CONV).collect();
    sorted_indices.sort_by(|&a, &b| {
        let len_a = VOCAB_CONV.get(a).map(|s| s.len()).unwrap_or(0);
        let len_b = VOCAB_CONV.get(b).map(|s| s.len()).unwrap_or(0);
        len_b.cmp(&len_a)
    });

    while cursor < bytes.len() {
        let mut matched = false;
        let remaining_str = lower.get(cursor..).unwrap_or("");

        for &tid in sorted_indices.iter() {
            if let Some(sub) = VOCAB_CONV.get(tid) {
                if remaining_str.starts_with(sub) {
                    tokens.push(tid);
                    cursor += sub.len();
                    matched = true;
                    break;
                }
            }
        }
        if !matched {
            tokens.push(0);
            cursor += 1;
        }
    }

    tokens
}

/// Extracts whole-word and domain-matched semantic roots from a natural language prompt
/// without leaking 2-letter/3-letter bound syllable slices into logit resonance.
pub fn extract_semantic_prompt_roots(prompt: &str) -> Vec<usize> {
    let lower = prompt.to_lowercase();
    let mut roots = Vec::new();

    for raw_word in lower.split(|c: char| !c.is_alphanumeric()) {
        let word = raw_word.trim();
        if word.len() < 2 {
            continue;
        }

        // 1. Check exact match in VOCAB_CONV free words
        let mut exact_found = false;
        for (idx, &entry) in VOCAB_CONV.iter().enumerate() {
            if entry == word && is_free_word_token(idx) {
                if !roots.iter().any(|&r| r == idx) {
                    roots.push(idx);
                }
                exact_found = true;
                break;
            }
        }
        if exact_found {
            continue;
        }

        // 2. Check prefix/substring match against Core Domain words (186..236)
        for idx in 186..236 {
            if let Some(&domain_tok) = VOCAB_CONV.get(idx) {
                if domain_tok.len() >= 3 && (word.starts_with(domain_tok) || word.contains(domain_tok)) {
                    if !roots.iter().any(|&r| r == idx) {
                        roots.push(idx);
                    }
                }
            }
        }

        // 3. Semantic synonym bridges for hardware/architecture vocabulary
        let bridge_opt = match word {
            "silicon" | "cluster" | "tensor" | "intel" | "devices" | "edge" => Some(223), // mesh
            "workstation" | "garlock" | "server" | "gateway" => Some(221),                // host
            "quantized" | "deltas" | "weights" | "checkpoint" => Some(234),               // shard
            "calibrate" | "projection" | "matrix" | "gosset" => Some(207),                // geom
            "invariants" | "cohomology" | "manifold" => Some(211),                        // sheaf
            "carrier" | "clock" | "frequency" | "resonance" => Some(219),                 // hz
            "observer" | "maintains" | "unifies" | "preserve" => Some(202),               // lock
            "distributes" | "streams" | "transduces" => Some(232),                        // sync
            "latency" | "microsecond" | "reflex" => Some(227),                            // fast
            _ => None,
        };
        if let Some(bridged) = bridge_opt {
            if !roots.iter().any(|&r| r == bridged) {
                roots.push(bridged);
            }
        }
    }

    if roots.is_empty() {
        roots.push(223); // mesh
        roots.push(225); // core
        roots.push(202); // lock
    }

    roots
}

/// Morphologically recombines and stitches 240-D tokens into coherent grammatical SVO clauses
pub fn recombine_and_stitch_subwords(token_ids: &[usize]) -> String {
    let mut words: Vec<String> = Vec::new();
    let mut i = 0;

    while i < token_ids.len() {
        let tid = token_ids.get(i).copied().unwrap_or(0);
        if tid == 0 || tid >= 236 {
            i += 1;
            continue;
        }

        let next_tid = token_ids.get(i + 1).copied().unwrap_or(0);

        // Compound morphological pair recombination (poly + tope -> polytope)
        if tid == 209 && next_tid == 210 {
            words.push(String::from("polytope"));
            i += 2;
            continue;
        }
        if tid == 184 && next_tid == 187 {
            words.push(String::from("act-omega"));
            i += 2;
            continue;
        }

        let slot_in_clause = words.len() % 7;
        let rendered = match tid {
            188 => String::from("E8"),
            190 => String::from("topological"),
            193 => String::from("0.17259 rad"),
            207 => String::from("geometric"),
            209 => String::from("quantized"),
            210 => String::from("polytope"),
            215 => String::from("infers"),
            218 => String::from("18.4 us"),
            219 => String::from("15.0 Hz"),
            220 => String::from("ReBAR"),
            232 => {
                if slot_in_clause == 3 {
                    String::from("synchronizes")
                } else {
                    String::from("synchronized")
                }
            }
            202 => {
                if slot_in_clause == 3 {
                    String::from("locks")
                } else {
                    String::from("locked")
                }
            }
            195 => {
                if slot_in_clause == 3 {
                    String::from("flows")
                } else {
                    String::from("flow")
                }
            }
            216 => {
                if slot_in_clause == 3 {
                    String::from("loads")
                } else {
                    String::from("loaded")
                }
            }
            222 => {
                if slot_in_clause == 3 {
                    String::from("links")
                } else {
                    String::from("linked")
                }
            }
            186 => {
                if slot_in_clause == 3 {
                    String::from("acts")
                } else {
                    String::from("active")
                }
            }
            _ => {
                if let Some(&raw) = VOCAB_CONV.get(tid) {
                    String::from(raw.trim())
                } else {
                    String::new()
                }
            }
        };

        if !rendered.is_empty() {
            words.push(rendered);
        }
        i += 1;
    }

    let mut out = String::new();
    for (idx, w) in words.iter().enumerate() {
        if idx > 0 {
            if idx % 7 == 0 {
                out.push_str("; ");
            } else {
                out.push(' ');
            }
        }
        out.push_str(w);
    }
    out
}

/// Detokenize a slice of token ids back into natural string.
/// Uses raw concatenation when control delimiters (236..=239) or spaces (0) are present,
/// and delegates to morphological SVO stitching for pure semantic token sequences.
pub fn detokenize_conversational(tokens: &[usize]) -> String {
    let has_delimiters_or_spaces = tokens.iter().any(|&t| t == 0 || t >= 236);
    if !has_delimiters_or_spaces && !tokens.is_empty() {
        return recombine_and_stitch_subwords(tokens);
    }

    let mut output = String::new();
    for &tid in tokens.iter() {
        if let Some(s) = VOCAB_CONV.get(tid) {
            output.push_str(s);
        }
    }
    output
}

/// Creates instruction-masked training pairs: (in_tok, target_tok, is_supervised_loss)
pub fn create_masked_training_pairs(tokens: &[usize]) -> Vec<(usize, usize, bool)> {
    let mut pairs = Vec::with_capacity(tokens.len().saturating_sub(1));
    let mut in_response = false;

    for i in 0..tokens.len().saturating_sub(1) {
        let in_tok = tokens.get(i).copied().unwrap_or(0);
        let target_tok = tokens.get(i + 1).copied().unwrap_or(0);

        if in_tok == TOKEN_RESPONSE {
            in_response = true;
        } else if in_tok == TOKEN_EOS {
            in_response = false;
        }

        pairs.push((in_tok, target_tok, in_response));
    }

    pairs
}