export const VOCAB_SIZE = 64;

export const GLYPH_TABLE = [
  ' ', 
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  '-', '.', ',', ':', ';', '!', '?', '_', '/', '\\', 
  '(', ')', '[', ']', '{', '}', '+', '=', '*', '<', '>', '"', '\'', '@', '#', '%', '&'
];

export const IPA_TABLE = [
  " ", 
  "æ", "b", "k", "d", "ɛ", "f", "ɡ", "h", "ɪ", "dʒ", "k", "l", "m", 
  "n", "ɒ", "p", "kw", "ɹ", "s", "t", "ʌ", "v", "w", "ks", "j", "z",
  "zɪəɹoʊ", "wʌn", "tuː", "θɹiː", "fɔː", "faɪv", "sɪks", "sɛvən", "eɪt", "naɪn",
  "-", "‖", ",", ":", ";", "!", "?", "_", "/", "\\",
  "(", ")", "[", "]", "{", "}", "+", "=", "*", "<", ">", "\"", "'", "@", "#", "%", "&"
];

export function tokenizeText(text: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < text.length; i++) {
    const c = text[i].toLowerCase();
    const idx = GLYPH_TABLE.indexOf(c);
    out.push(idx !== -1 ? idx : c.charCodeAt(0) % VOCAB_SIZE);
  }
  return out;
}

export function detokenizeText(tokens: number[]): string {
  return tokens.map((t) => GLYPH_TABLE[((t % VOCAB_SIZE) + VOCAB_SIZE) % VOCAB_SIZE] || "?").join("");
}

export function detokenizePhonetic(tokens: number[]): string {
  const parts = tokens.map((t) => IPA_TABLE[((t % VOCAB_SIZE) + VOCAB_SIZE) % VOCAB_SIZE] || "").filter((s) => s.length > 0);
  return `/${parts.join(".")}/`;
}