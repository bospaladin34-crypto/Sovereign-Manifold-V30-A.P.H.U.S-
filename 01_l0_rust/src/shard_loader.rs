use std::fs::{self, File};
use std::io::{Read, Result};
use std::path::Path;

pub const BINSHARD_MAGIC: &[u8] = b"ACT_OMEGA_BINSHARD_V30\0";
pub const HEADER_SIZE: usize = 64;

#[derive(Debug, Clone)]
pub struct Shard {
    pub filename: String,
    pub curriculum_id: u8,
    pub token_count: usize,
    pub tokens: Vec<usize>,
}

pub struct ShardDataset {
    pub shards: Vec<Shard>,
    pub flat_tokens: Vec<usize>,
}

impl ShardDataset {
    /// Loads and parses all .binshard files from the canonical vault directory
    pub fn load_from_directory<P: AsRef<Path>>(dir: P) -> Result<Self> {
        let mut shards = Vec::new();
        let mut flat_tokens = Vec::new();

        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("binshard") {
                    if let Ok(mut file) = File::open(&path) {
                        let mut buffer = Vec::new();
                        if file.read_to_end(&mut buffer).is_ok() && buffer.len() >= HEADER_SIZE {
                            // Validate 24-byte magic header
                            if buffer.get(..23) == Some(&BINSHARD_MAGIC[..23]) {
                                let curriculum_id = buffer.get(24).copied().unwrap_or(0);
                                
                                // Read 32-bit token count (offset 28..32)
                                let count_bytes = buffer.get(28..32).unwrap_or(&[0; 4]);
                                let token_count = u32::from_le_bytes([
                                    count_bytes.first().copied().unwrap_or(0),
                                    count_bytes.get(1).copied().unwrap_or(0),
                                    count_bytes.get(2).copied().unwrap_or(0),
                                    count_bytes.get(3).copied().unwrap_or(0),
                                ]) as usize;

                                if let Some(token_payload) = buffer.get(HEADER_SIZE..HEADER_SIZE + token_count) {
                                    let mut parsed_tokens = Vec::with_capacity(token_count);
                                    for &byte in token_payload.iter() {
                                        parsed_tokens.push((byte % 64) as usize);
                                    }

                                    flat_tokens.extend_from_slice(&parsed_tokens);
                                    shards.push(Shard {
                                        filename: entry.file_name().to_string_lossy().to_string(),
                                        curriculum_id,
                                        token_count,
                                        tokens: parsed_tokens,
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        Ok(Self {
            shards,
            flat_tokens,
        })
    }

    pub fn total_tokens(&self) -> usize {
        self.flat_tokens.len()
    }

    /// Extracts sequential next-token training pairs (input[i], target[i+1])
    pub fn get_training_pair(&self, index: usize) -> Option<(usize, usize)> {
        if self.flat_tokens.len() < 2 {
            return None;
        }
        let pos = index % (self.flat_tokens.len() - 1);
        let input_tok = self.flat_tokens.get(pos).copied()?;
        let target_tok = self.flat_tokens.get(pos + 1).copied()?;
        Some((input_tok, target_tok))
    }
}