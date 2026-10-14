// 01_l0_core/src/vocab_e8_table.rs
// Dual E8-Phonetic Vocabulary Lookup Table & Bidirectional Detokenizer
// Enforces strict Zero-Square-Bracket memory safety via pattern matching

pub const VOCAB_SIZE: usize = 64;

pub const GLYPH_TABLE: [char; VOCAB_SIZE] = [
    ' ', 
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    '-', '.', ',', ':', ';', '!', '?', '_', '/', '\\', 
    '(', ')', '[', ']', '{', '}', '+', '=', '*', '<', '>', '"', '\'', '@', '#', '%', '&'
];

pub const IPA_TABLE: [&'static str; VOCAB_SIZE] = [
    " ", 
    "æ", "b", "k", "d", "ɛ", "f", "ɡ", "h", "ɪ", "dʒ", "k", "l", "m", 
    "n", "ɒ", "p", "kw", "ɹ", "s", "t", "ʌ", "v", "w", "ks", "j", "z",
    "zɪəɹoʊ", "wʌn", "tuː", "θɹiː", "fɔː", "faɪv", "sɪks", "sɛvən", "eɪt", "naɪn",
    "-", "‖", ",", ":", ";", "!", "?", "_", "/", "\\",
    "(", ")", "[", "]", "{", "}", "+", "=", "*", "<", ">", "\"", "'", "@", "#", "%", "&"
];

#[derive(Debug, Clone, Copy)]
pub struct AcousticFormant {
    pub f1_hz: f32,
    pub f2_hz: f32,
    pub f3_hz: f32,
}

#[derive(Debug, Clone, Copy)]
pub struct VocabEntry {
    pub token_id: usize,
    pub glyph: char,
    pub ipa: &'static str,
    pub formant: AcousticFormant,
    pub e8_root_index: usize,
}

pub struct VocabE8Table;

impl VocabE8Table {
    pub fn get_entry(token: usize) -> VocabEntry {
        let t = token % VOCAB_SIZE;
        let glyph = match GLYPH_TABLE.get(t) {
            Some(&c) => c,
            None => '?',
        };
        let ipa = match IPA_TABLE.get(t) {
            Some(&s) => s,
            None => "",
        };

        let f1 = 300.0 + ((t * 11) % 600) as f32;
        let f2 = 900.0 + ((t * 23) % 1500) as f32;
        let f3 = 2200.0 + ((t * 17) % 1000) as f32;

        VocabEntry {
            token_id: t,
            glyph,
            ipa,
            formant: AcousticFormant { f1_hz: f1, f2_hz: f2, f3_hz: f3 },
            e8_root_index: (t * 3) % 240,
        }
    }

    pub fn tokenize_text(text: &str) -> Vec<usize> {
        text.chars().map(|c| {
            let lower = c.to_ascii_lowercase();
            match lower {
                ' ' => 0,
                'a'..='z' => 1 + (lower as usize - 'a' as usize),
                '0'..='9' => 27 + (lower as usize - '0' as usize),
                '-' => 37,
                '.' => 38,
                ',' => 39,
                ':' => 40,
                ';' => 41,
                '!' => 42,
                '?' => 43,
                '_' => 44,
                '/' => 45,
                '\\' => 46,
                '(' => 47,
                ')' => 48,
                '[' => 49,
                ']' => 50,
                '{' => 51,
                '}' => 52,
                '+' => 53,
                '=' => 54,
                '*' => 55,
                '<' => 56,
                '>' => 57,
                '"' => 58,
                '\'' => 59,
                '@' => 60,
                '#' => 61,
                '%' => 62,
                '&' => 63,
                _ => (c as usize) % VOCAB_SIZE,
            }
        }).collect()
    }

    pub fn detokenize_text(tokens: &[usize]) -> String {
        tokens.iter().map(|&t| Self::get_entry(t).glyph).collect()
    }

    pub fn detokenize_phonetic(tokens: &[usize]) -> String {
        let mut out = String::new();
        out.push('/');
        for (i, &t) in tokens.iter().enumerate() {
            if i > 0 && t != 0 {
                out.push('.');
            }
            out.push_str(Self::get_entry(t).ipa);
        }
        out.push('/');
        out
    }

    pub fn detokenize_acoustic(tokens: &[usize]) -> Vec<AcousticFormant> {
        tokens.iter().map(|&t| Self::get_entry(t).formant).collect()
    }
}