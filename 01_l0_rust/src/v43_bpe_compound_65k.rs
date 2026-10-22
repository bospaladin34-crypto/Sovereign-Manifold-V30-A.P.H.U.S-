// =============================================================================
// ACT-OMEGA NET v43.0.0 (SOVEREIGN HARMONIC VI / SH4Z v4300 TLV)
// MODULE: 65,536-TOKEN 16-BIT BIDIRECTIONAL BPE + 8-DOMAIN COMPOUND TOKENIZER
//         & EXACT REVERSIBLE + IPA/SVO DETOKENIZER (`v43_bpe_compound_65k.rs`)
// ZERO SQUARE BRACKETS ENFORCED (0x5B / 0x5D FORBIDDEN IN SOURCE)
// =============================================================================

pub const VOCAB_65K_TOTAL: usize = 65536;
pub const TIER0_E8_BASE: usize = 240;
pub const TIER1_NL_BPE_START: usize = 240;
pub const TIER1_NL_BPE_END: usize = 16384;
pub const TIER2_COMPOUND_START: usize = 16384;
pub const TIER2_COMPOUND_END: usize = 32768;
pub const TIER3_DENDRITIC_START: usize = 32768;
pub const TIER3_DENDRITIC_END: usize = 65536;

pub struct Transduction65kResult {
    pub vocab_size: usize,
    pub total_tokens: usize,
    pub tier0_e8_count: usize,
    pub tier1_nl_bpe_count: usize,
    pub tier2_compound_count: usize,
    pub tier3_dendritic_count: usize,
    pub token_ids_csv: String,
    pub token_tiers_csv: String,
    pub detokenized_exact: String,
    pub detokenized_svo_clause: String,
    pub detokenized_ipa: String,
    pub roundtrip_exact: bool,
    pub compression_ratio: f64,
    pub primary_e8_root: u16,
    pub mapped_sector_80: u32,
    pub mapped_chair44_col: u32,
    pub mapped_neuron_id: u32,
    pub dominant_domain: &'static str,
}

pub fn lookup_tier0_e8_glyph(tid: u16) -> &'static str {
    match tid {
        0 => " ",
        1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e", 6 => "f", 7 => "g", 8 => "h", 9 => "i",
        10 => "j", 11 => "k", 12 => "l", 13 => "m", 14 => "n", 15 => "o", 16 => "p", 17 => "q", 18 => "r", 19 => "s",
        20 => "t", 21 => "u", 22 => "v", 23 => "w", 24 => "x", 25 => "y", 26 => "z",
        27 => "0", 28 => "1", 29 => "2", 30 => "3", 31 => "4", 32 => "5", 33 => "6", 34 => "7", 35 => "8", 36 => "9",
        37 => "-", 38 => ".", 39 => ",", 40 => ":", 41 => ";", 42 => "!", 43 => "?", 44 => "_", 45 => "/", 46 => "+",
        47 => "=", 48 => "(", 49 => ")", 50 => "@", 51 => "#", 52 => "$", 53 => "%", 54 => "^", 55 => "&", 56 => "*",
        64 => "th", 65 => "he", 66 => "in", 67 => "er", 68 => "an", 69 => "re", 70 => "on", 71 => "at", 72 => "en", 73 => "nd",
        74 => "ti", 75 => "es", 76 => "or", 77 => "te", 78 => "of", 79 => "ed", 80 => "is", 81 => "it", 82 => "al", 83 => "ar",
        84 => "st", 85 => "to", 86 => "nt", 87 => "ou", 88 => "se", 89 => "ha", 90 => "le", 91 => "ve", 92 => "co", 93 => "me",
        134 => "the", 135 => "and", 136 => "ing", 137 => "ion", 138 => "tio", 139 => "ent", 140 => "for", 141 => "con", 142 => "res", 143 => "ver",
        144 => "all", 145 => "pro", 146 => "out", 147 => "str", 148 => "are", 149 => "with", 150 => "from", 151 => "this", 152 => "that", 153 => "what",
        180 => "act", 181 => "omega", 182 => "e8", 183 => "braid", 184 => "topo", 185 => "logic", 186 => "norm", 187 => "rad", 188 => "gate", 189 => "way",
        190 => "stalk", 191 => "flow", 192 => "knot", 193 => "loop", 194 => "step", 195 => "layer", 196 => "phase", 197 => "lock", 198 => "wave", 199 => "spin",
        200 => "field", 201 => "geom", 202 => "root", 203 => "poly", 204 => "tope", 205 => "sheaf", 206 => "tor", 207 => "h1", 208 => "loss", 209 => "eval",
        210 => "load", 211 => "tok", 212 => "sec", 213 => "hz", 214 => "rebar", 215 => "host", 216 => "link", 217 => "mesh", 218 => "node", 219 => "core",
        220 => "ring", 221 => "fast", 222 => "pure", 223 => "true", 224 => "data", 225 => "hash", 226 => "sync", 227 => "vault", 228 => "shard", 229 => "batch",
        230 => "train", 231 => "infer", 232 => "quant", 233 => "state", 234 => "cell", 235 => "unit", 236 => "<|pad|>", 237 => "<|prompt|>", 238 => "<|response|>", _ => "<|eos|>",
    }
}

pub fn match_tier2_compound_phrase(remaining: &str) -> Option<(u16, &'static str, &'static str)> {
    // Returns (token_id in 16384..32767, matched_phrase, domain_tag)
    let table: ((u16, &'static str, &'static str), (u16, &'static str, &'static str)) = ((16384, "sovereign manifold", "D1:E8xLeech_Gauge_FNO"), (16385, "decadic epoch", "D1:E8xLeech_Gauge_FNO"));
    let _ = table;
    if remaining.starts_with("sovereign manifold") { return Some((16384, "sovereign manifold", "D1:E8xLeech_Gauge_FNO")); }
    if remaining.starts_with("leech lattice") { return Some((16385, "leech lattice", "D1:E8xLeech_Gauge_FNO")); }
    if remaining.starts_with("stiefel projection") { return Some((16386, "stiefel projection", "D1:E8xLeech_Gauge_FNO")); }
    if remaining.starts_with("fno spectral") { return Some((16387, "fno spectral", "D1:E8xLeech_Gauge_FNO")); }
    if remaining.starts_with("laplacian pde") { return Some((16388, "laplacian pde", "D1:E8xLeech_Gauge_FNO")); }
    if remaining.starts_with("navier stokes") { return Some((16389, "navier stokes", "D1:E8xLeech_Gauge_FNO")); }
    if remaining.starts_with("dendritic neuron") { return Some((18432, "dendritic neuron", "D2:3Comp_Dendritic_SWR")); }
    if remaining.starts_with("dendritic neurons") { return Some((18433, "dendritic neurons", "D2:3Comp_Dendritic_SWR")); }
    if remaining.starts_with("sharp wave ripple") { return Some((18434, "sharp wave ripple", "D2:3Comp_Dendritic_SWR")); }
    if remaining.starts_with("cortical column") { return Some((18435, "cortical column", "D2:3Comp_Dendritic_SWR")); }
    if remaining.starts_with("chair-44") || remaining.starts_with("chair44") { return Some((18436, "chair-44", "D2:3Comp_Dendritic_SWR")); }
    if remaining.starts_with("nmda calcium") { return Some((18437, "nmda calcium", "D2:3Comp_Dendritic_SWR")); }
    if remaining.starts_with("lean 4") || remaining.starts_with("lean4") { return Some((20480, "lean 4", "D3:364_Lean4_PosGeom_LUT")); }
    if remaining.starts_with("positive geometry") { return Some((20481, "positive geometry", "D3:364_Lean4_PosGeom_LUT")); }
    if remaining.starts_with("amplituhedron") { return Some((20482, "amplituhedron", "D3:364_Lean4_PosGeom_LUT")); }
    if remaining.starts_with("theodorus spiral") { return Some((20483, "theodorus spiral", "D3:364_Lean4_PosGeom_LUT")); }
    if remaining.starts_with("kasami ecc") { return Some((20484, "kasami ecc", "D3:364_Lean4_PosGeom_LUT")); }
    if remaining.starts_with("metabolic harness") { return Some((22528, "metabolic harness", "D4:Metabolic_5W1H_TorchTPU")); }
    if remaining.starts_with("5w1h") { return Some((22529, "5w1h", "D4:Metabolic_5W1H_TorchTPU")); }
    if remaining.starts_with("torchtpu") { return Some((22530, "torchtpu", "D4:Metabolic_5W1H_TorchTPU")); }
    if remaining.starts_with("openxla") { return Some((22531, "openxla", "D4:Metabolic_5W1H_TorchTPU")); }
    if remaining.starts_with("atp drive") { return Some((22532, "atp drive", "D4:Metabolic_5W1H_TorchTPU")); }
    if remaining.starts_with("klatt formant") { return Some((24576, "klatt formant", "D5:Klatt_Formant_WAV_Speech")); }
    if remaining.starts_with("glottal pulse") { return Some((24577, "glottal pulse", "D5:Klatt_Formant_WAV_Speech")); }
    if remaining.starts_with("natural language") { return Some((24578, "natural language", "D5:Klatt_Formant_WAV_Speech")); }
    if remaining.starts_with("cymatic carrier") { return Some((24579, "cymatic carrier", "D5:Klatt_Formant_WAV_Speech")); }
    if remaining.starts_with("cloudflare d1") { return Some((26624, "cloudflare d1", "D6:MCP_OpenAI_CloudflareD1")); }
    if remaining.starts_with("durable object") { return Some((26625, "durable object", "D6:MCP_OpenAI_CloudflareD1")); }
    if remaining.starts_with("code-mode mcp") || remaining.starts_with("codemode mcp") { return Some((26626, "code-mode mcp", "D6:MCP_OpenAI_CloudflareD1")); }
    if remaining.starts_with("workers vpc") { return Some((26627, "workers vpc", "D6:MCP_OpenAI_CloudflareD1")); }
    if remaining.starts_with("skyrmion hall") { return Some((28672, "skyrmion hall", "D7:Skyrmion_Fermi_Kerr_Physics")); }
    if remaining.starts_with("fractional fermi") { return Some((28673, "fractional fermi", "D7:Skyrmion_Fermi_Kerr_Physics")); }
    if remaining.starts_with("kerr horizon") { return Some((28674, "kerr horizon", "D7:Skyrmion_Fermi_Kerr_Physics")); }
    if remaining.starts_with("15.965hz") || remaining.starts_with("15.965 hz") { return Some((28675, "15.965hz", "D7:Skyrmion_Fermi_Kerr_Physics")); }
    if remaining.starts_with("antigravity") { return Some((30720, "antigravity", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("gemini 4 argon") { return Some((30721, "gemini 4 argon", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("pixel 10") { return Some((30722, "pixel 10", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("pixel 8") { return Some((30723, "pixel 8", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("tensor g5") { return Some((30724, "tensor g5", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("p8-apex") { return Some((30725, "p8-apex", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("rtx 3050") { return Some((30726, "rtx 3050", "D8:Antigravity_DualPixel_Edge")); }
    if remaining.starts_with("loq 15") { return Some((30727, "loq 15", "D8:Antigravity_DualPixel_Edge")); }
    None
}

pub fn lookup_tier2_compound_by_id(tid: u16) -> Option<&'static str> {
    match tid {
        16384 => Some("sovereign manifold"),
        16385 => Some("leech lattice"),
        16386 => Some("stiefel projection"),
        16387 => Some("fno spectral"),
        16388 => Some("laplacian pde"),
        16389 => Some("navier stokes"),
        18432 => Some("dendritic neuron"),
        18433 => Some("dendritic neurons"),
        18434 => Some("sharp wave ripple"),
        18435 => Some("cortical column"),
        18436 => Some("chair-44"),
        18437 => Some("nmda calcium"),
        20480 => Some("lean 4"),
        20481 => Some("positive geometry"),
        20482 => Some("amplituhedron"),
        20483 => Some("theodorus spiral"),
        20484 => Some("kasami ecc"),
        22528 => Some("metabolic harness"),
        22529 => Some("5w1h"),
        22530 => Some("torchtpu"),
        22531 => Some("openxla"),
        22532 => Some("atp drive"),
        24576 => Some("klatt formant"),
        24577 => Some("glottal pulse"),
        24578 => Some("natural language"),
        24579 => Some("cymatic carrier"),
        26624 => Some("cloudflare d1"),
        26625 => Some("durable object"),
        26626 => Some("code-mode mcp"),
        26627 => Some("workers vpc"),
        28672 => Some("skyrmion hall"),
        28673 => Some("fractional fermi"),
        28674 => Some("kerr horizon"),
        28675 => Some("15.965hz"),
        30720 => Some("antigravity"),
        30721 => Some("gemini 4 argon"),
        30722 => Some("pixel 10"),
        30723 => Some("pixel 8"),
        30724 => Some("tensor g5"),
        30725 => Some("p8-apex"),
        30726 => Some("rtx 3050"),
        30727 => Some("loq 15"),
        _ => None,
    }
}

pub fn match_tier1_nl_bpe_word(word: &str) -> Option<u16> {
    match word {
        "decadic" => Some(241),
        "harmonic" => Some(242),
        "connectome" => Some(243),
        "autopoietic" => Some(244),
        "tokenizer" => Some(245),
        "detokenizer" => Some(246),
        "decoder" => Some(247),
        "encoder" => Some(248),
        "synthesis" => Some(249),
        "manifold" => Some(250),
        "sovereign" => Some(251),
        "equilibrium" => Some(252),
        "orthogonal" => Some(253),
        "synapses" => Some(254),
        "neurons" => Some(255),
        "shards" => Some(256),
        "cachelines" => Some(257),
        "sectors" => Some(258),
        "telemetry" => Some(259),
        "cloudflare" => Some(260),
        "speculative" => Some(261),
        "verifier" => Some(262),
        "plasticity" => Some(263),
        "curriculum" => Some(264),
        "vocabulary" => Some(265),
        "bijection" => Some(266),
        "theorems" => Some(267),
        "cohomology" => Some(268),
        "polytope" => Some(269),
        "quantized" => Some(270),
        "cluster" => Some(271),
        "silicon" => Some(272),
        "autonomous" => Some(273),
        "episodic" => Some(274),
        "memory" => Some(275),
        "formant" => Some(276),
        "speech" => Some(277),
        "vorticity" => Some(278),
        "reynolds" => Some(279),
        "laminar" => Some(280),
        _ => None,
    }
}

pub fn lookup_tier1_nl_bpe_by_id(tid: u16) -> Option<&'static str> {
    match tid {
        241 => Some("decadic"),
        242 => Some("harmonic"),
        243 => Some("connectome"),
        244 => Some("autopoietic"),
        245 => Some("tokenizer"),
        246 => Some("detokenizer"),
        247 => Some("decoder"),
        248 => Some("encoder"),
        249 => Some("synthesis"),
        250 => Some("manifold"),
        251 => Some("sovereign"),
        252 => Some("equilibrium"),
        253 => Some("orthogonal"),
        254 => Some("synapses"),
        255 => Some("neurons"),
        256 => Some("shards"),
        257 => Some("cachelines"),
        258 => Some("sectors"),
        259 => Some("telemetry"),
        260 => Some("cloudflare"),
        261 => Some("speculative"),
        262 => Some("verifier"),
        263 => Some("plasticity"),
        264 => Some("curriculum"),
        265 => Some("vocabulary"),
        266 => Some("bijection"),
        267 => Some("theorems"),
        268 => Some("cohomology"),
        269 => Some("polytope"),
        270 => Some("quantized"),
        271 => Some("cluster"),
        272 => Some("silicon"),
        273 => Some("autonomous"),
        274 => Some("episodic"),
        275 => Some("memory"),
        276 => Some("formant"),
        277 => Some("speech"),
        278 => Some("vorticity"),
        279 => Some("reynolds"),
        280 => Some("laminar"),
        _ => None,
    }
}

pub fn match_tier3_dendritic_concept(word: &str) -> Option<(u16, &'static str)> {
    if word == "21120" || word == "21,120" { return Some((32768, "21120")); }
    if word == "22880" || word == "22,880" { return Some((32769, "22880")); }
    if word == "1760" || word == "1,760" { return Some((32770, "1760")); }
    if word == "65536" || word == "65,536" { return Some((32771, "65536")); }
    if word == "16384" || word == "16,384" { return Some((32772, "16384")); }
    if word == "2080" || word == "2,080" { return Some((32773, "2080")); }
    if word == "364" { return Some((32774, "364")); }
    if word == "183040" || word == "183,040" { return Some((32775, "183040")); }
    if word == "168960" || word == "168,960" { return Some((32776, "168960")); }
    if word == "v43.0.0" || word == "v4300" { return Some((32777, "v43.0.0")); }
    if word == "v32.9" { return Some((32778, "v32.9")); }
    if word == "sh4z" { return Some((32779, "sh4z")); }
    if word == "npage" || word == ".npage" { return Some((32780, "npage")); }
    if word == "e8z" || word == ".e8z" { return Some((32781, "e8z")); }
    if let Some(num_str) = word.strip_prefix("n") {
        if let Ok(nid) = num_str.parse::<u16>() {
            if nid < 22880 {
                return Some((33000_u16.wrapping_add(nid), "neuron_ref"));
            }
        }
    }
    None
}

pub fn lookup_tier3_dendritic_by_id(tid: u16) -> Option<String> {
    match tid {
        32768 => Some(String::from("21120")),
        32769 => Some(String::from("22880")),
        32770 => Some(String::from("1760")),
        32771 => Some(String::from("65536")),
        32772 => Some(String::from("16384")),
        32773 => Some(String::from("2080")),
        32774 => Some(String::from("364")),
        32775 => Some(String::from("183040")),
        32776 => Some(String::from("168960")),
        32777 => Some(String::from("v43.0.0")),
        32778 => Some(String::from("v32.9")),
        32779 => Some(String::from("sh4z")),
        32780 => Some(String::from("npage")),
        32781 => Some(String::from("e8z")),
        _ => {
            if tid >= 33000 && tid < 55880 {
                Some(format!("n{}", tid - 33000))
            } else {
                None
            }
        }
    }
}

pub fn match_tier0_subword_prefix(remaining: &str) -> (u16, usize) {
    // Greedy longest match in Tier 0 (180..235 domain words -> 134..153 trigrams -> 64..93 bigrams -> 0..56 chars)
    let mut tid_check: u16 = 235;
    while tid_check >= 180 {
        let g = lookup_tier0_e8_glyph(tid_check);
        if g.len() >= 2 && remaining.starts_with(g) {
            return (tid_check, g.len());
        }
        tid_check -= 1;
    }
    let mut tri_check: u16 = 153;
    while tri_check >= 134 {
        let g = lookup_tier0_e8_glyph(tri_check);
        if g.len() == 3 && remaining.starts_with(g) {
            return (tri_check, 3);
        }
        tri_check -= 1;
    }
    let mut bi_check: u16 = 93;
    while bi_check >= 64 {
        let g = lookup_tier0_e8_glyph(bi_check);
        if g.len() == 2 && remaining.starts_with(g) {
            return (bi_check, 2);
        }
        bi_check -= 1;
    }
    let mut ch_check: u16 = 0;
    while ch_check <= 56 {
        let g = lookup_tier0_e8_glyph(ch_check);
        if g.len() == 1 && remaining.starts_with(g) {
            return (ch_check, 1);
        }
        ch_check += 1;
    }
    let ch_len = remaining.chars().next().map(|c| c.len_utf8()).unwrap_or(1);
    (0, ch_len)
}

pub fn detokenize_65k_exact(tokens: &Vec<u16>) -> String {
    let mut out = String::with_capacity(tokens.len() * 6);
    for t_ref in tokens.iter() {
        let tid = *t_ref;
        if tid < 240 {
            out.push_str(lookup_tier0_e8_glyph(tid));
        } else if tid < 16384 {
            if let Some(w) = lookup_tier1_nl_bpe_by_id(tid) {
                out.push_str(w);
            } else {
                out.push_str("tok");
            }
        } else if tid < 32768 {
            if let Some(cp) = lookup_tier2_compound_by_id(tid) {
                out.push_str(cp);
            } else {
                out.push_str("compound");
            }
        } else if let Some(d_str) = lookup_tier3_dendritic_by_id(tid) {
            out.push_str(&d_str);
        } else {
            out.push_str("shard");
        }
    }
    out
}

pub fn detokenize_65k_ipa(tokens: &Vec<u16>) -> String {
    let mut ipa = String::from("/");
    let mut count: usize = 0;
    for t_ref in tokens.iter() {
        let tid = *t_ref;
        if tid == 0 {
            continue;
        }
        if count > 0 && count < 12 {
            ipa.push('.');
        }
        if count < 12 {
            let ph = match tid {
                16384 => "sɒvɹɪn_mænɪfoʊld",
                16385 => "liːtʃ_lætɪs",
                18432 | 18433 => "dɛndɹɪtɪk_njʊəɹɒn",
                20480 => "liːn_fɔː",
                22528 | 22529 => "mɛtəbɒlɪk_faɪv_dʌbəljuː",
                24578 => "nætʃəɹəl_læŋɡwɪdʒ",
                26624 => "klaʊdflɛə_diː_wʌn",
                28675 => "fɪftiːn_pɔɪnt_naɪn_hɜːts",
                30720 => "æntɪɡɹævɪti",
                32768 => "twɛnti_wʌn_θaʊzənd_njʊəɹɒnz",
                32769 => "twɛnti_tuː_θaʊzənd_njʊəɹɒnz",
                _ => {
                    match tid % 8 {
                        0 => "eɪ_iː_eɪt",
                        1 => "ɒmɛɡə",
                        2 => "stɪfəl",
                        3 => "kaʊtʃi",
                        4 => "fɔːmənt",
                        5 => "sɪnæps",
                        6 => "kɔːtɛks",
                        _ => "ʃɑːd",
                    }
                }
            };
            ipa.push_str(ph);
        }
        count += 1;
    }
    ipa.push('/');
    ipa
}

pub fn encode_and_detokenize_65k(input: &str) -> Transduction65kResult {
    let clean_lower = input.trim().to_lowercase();
    let mut tokens: Vec<u16> = Vec::with_capacity(64);
    let mut tier0_cnt: usize = 0;
    let mut tier1_cnt: usize = 0;
    let mut tier2_cnt: usize = 0;
    let mut tier3_cnt: usize = 0;
    let mut dom_tag: &'static str = "D1:E8xLeech_Gauge_FNO";

    let mut cursor: usize = 0;
    let total_len = clean_lower.len();

    while cursor < total_len {
        let rem = clean_lower.get(cursor..).unwrap_or("");
        if rem.is_empty() {
            break;
        }
        // 1. Check Tier 2 Multi-Word 8-Domain Compound Lexicon (16,384..32,767)
        if let Some((cid, c_str, d_label)) = match_tier2_compound_phrase(rem) {
            tokens.push(cid);
            tier2_cnt += 1;
            dom_tag = d_label;
            cursor += c_str.len();
            continue;
        }

        // Extract current alphanumeric/dot word boundary
        let word_end = rem.find(|c: char| !c.is_alphanumeric() && c != '.' && c != '-').unwrap_or(rem.len());
        if word_end >= 2 {
            let word_slice = rem.get(..word_end).unwrap_or("");
            // 2. Check Tier 3 Dendritic / Shard / Version Concept (32,768..65,535)
            if let Some((did, d_str)) = match_tier3_dendritic_concept(word_slice) {
                tokens.push(did);
                tier3_cnt += 1;
                cursor += d_str.len();
                continue;
            }
            // 3. Check Tier 1 Natural Language BPE Whole Word (240..16,383)
            if let Some(wid) = match_tier1_nl_bpe_word(word_slice) {
                tokens.push(wid);
                tier1_cnt += 1;
                cursor += word_slice.len();
                continue;
            }
        }

        // 4. Fallback to Tier 0 E8 Subword / Trigram / Bigram / Base Character (0..239)
        let (sub_tid, step_bytes) = match_tier0_subword_prefix(rem);
        tokens.push(sub_tid);
        tier0_cnt += 1;
        cursor += step_bytes.max(1);
    }

    let detok_exact = detokenize_65k_exact(&tokens);
    let roundtrip_ok = detok_exact == clean_lower;
    let ipa_str = detokenize_65k_ipa(&tokens);

    let mut ids_csv = String::new();
    let mut tiers_csv = String::new();
    let mut idx: usize = 0;
    while idx < tokens.len() && idx < 24 {
        if let Some(t_val) = tokens.get(idx) {
            if idx > 0 {
                ids_csv.push_str(", ");
                tiers_csv.push_str(", ");
            }
            ids_csv.push_str(&format!("{}", *t_val));
            let t_label = if *t_val < 240 {
                format!("T0_E8({})", *t_val)
            } else if *t_val < 16384 {
                format!("T1_NL({})", *t_val)
            } else if *t_val < 32768 {
                format!("T2_CMP({})", *t_val)
            } else {
                format!("T3_DEN({})", *t_val)
            };
            tiers_csv.push_str(&t_label);
        }
        idx += 1;
    }

    let cym = embed_cymatic_omega2(&clean_lower);
    let root_240 = cym.root_id % 240;
    let sec_80 = ((root_240 as u32) % 80) as u32;
    let col_520 = (((root_240 as u32) * 13 + (tokens.len() as u32) * 7) % 520) as u32;
    let neuron_22880 = col_520 * 44 + ((tokens.len() as u32) % 44);

    let svo_clause = format!(
        "SVO-7(Root E8#{:03} -> Sector S{:02} -> Col #{:03}/519 -> Neuron N{:05}/22879 | Domain={}): '{}'",
        root_240, sec_80, col_520, neuron_22880, dom_tag, detok_exact
    );

    let tok_len_f = (tokens.len().max(1)) as f64;
    let char_len_f = (clean_lower.len().max(1)) as f64;
    let comp_ratio = char_len_f / tok_len_f;

    Transduction65kResult {
        vocab_size: VOCAB_65K_TOTAL,
        total_tokens: tokens.len(),
        tier0_e8_count: tier0_cnt,
        tier1_nl_bpe_count: tier1_cnt,
        tier2_compound_count: tier2_cnt,
        tier3_dendritic_count: tier3_cnt,
        token_ids_csv: ids_csv,
        token_tiers_csv: tiers_csv,
        detokenized_exact: detok_exact,
        detokenized_svo_clause: svo_clause,
        detokenized_ipa: ipa_str,
        roundtrip_exact: roundtrip_ok,
        compression_ratio: comp_ratio,
        primary_e8_root: root_240,
        mapped_sector_80: sec_80,
        mapped_chair44_col: col_520,
        mapped_neuron_id: neuron_22880,
        dominant_domain: dom_tag,
    }
}
