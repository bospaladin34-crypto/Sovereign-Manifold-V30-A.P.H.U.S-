//! 240-Token Subword Dictionary and Maximum-Munch Tokenizer/Detokenizer
//! Bijectively mapped to the 240 Gosset E8 root vectors.

use crate::e8_roots::E8_ROOT_COUNT;

pub const VOCAB_SIZE_240: usize = E8_ROOT_COUNT;

pub static VOCAB_240: [&str; VOCAB_SIZE_240] = [
    // 0..63: 64 Base Characters (Backward compatible with Phase 1)
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
    "train", "infer", "quant", "state", "cell", "unit", "head", "self",
];

/// Maximum-munch greedy subword tokenizer
pub fn tokenize_subwords(text: &str) -> Vec<usize> {
    let lower = text.to_lowercase();
    let bytes = lower.as_bytes();
    let mut tokens = Vec::new();
    let mut cursor = 0;

    let mut sorted_indices: Vec<usize> = (0..VOCAB_SIZE_240).collect();
    sorted_indices.sort_by(|&a, &b| {
        let len_a = VOCAB_240.get(a).map(|s| s.len()).unwrap_or(0);
        let len_b = VOCAB_240.get(b).map(|s| s.len()).unwrap_or(0);
        len_b.cmp(&len_a)
    });

    while cursor < bytes.len() {
        let mut matched = false;
        let remaining_str = lower.get(cursor..).unwrap_or("");
        for &tid in sorted_indices.iter() {
            if let Some(sub) = VOCAB_240.get(tid) {
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

/// Detokenize a slice of token ids back into natural string
pub fn detokenize_subwords(tokens: &[usize]) -> String {
    let mut output = String::new();
    for &tid in tokens.iter() {
        if let Some(s) = VOCAB_240.get(tid) {
            output.push_str(s);
        }
    }
    output
}
