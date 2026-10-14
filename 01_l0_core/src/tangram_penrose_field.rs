// 01_l0_core/src/tangram_penrose_field.rs
// v30 Track 10: 7-Piece Tangram Polyforms & 2D Penrose Cut-and-Project Compute Fields
// Zero-Square-Bracket Rust Invariant Enforced

pub const TANGRAM_PIECES_PER_CLAUSE: usize = 7;
pub const TANGRAM_CLAUSE_AREA_UNITS: usize = 16;
pub const DUAL_TANGRAM_STALK_AREA: usize = 32;
pub const SANTOS_PENROSE_DEG: f32 = 108.0;
pub const GOLDEN_RATIO_PHI: f32 = 1.61803399;

pub struct TangramPenroseReport {
    pub single_clause_area_units: usize,
    pub dual_clause_stalk_units: usize,
    pub parallelogram_shear_det: f32,
    pub penrose_rhombus_area_ratio: f32,
    pub projected_field_coords: Vec<f32>,
}

/// Normalized integer area units of the 7 Tangram tans (sum = 16 per clause, 32 for 2 clauses)
#[inline]
pub fn tangram_piece_area_units(slot_idx: usize) -> usize {
    match slot_idx % TANGRAM_PIECES_PER_CLAUSE {
        0 => 4,
        1 => 4,
        2 => 2,
        3 => 1,
        4 => 2,
        5 => 1,
        _ => 2,
    }
}

pub fn project_tangram_penrose_field(svo_tokens: &Vec<usize>, shear_k: f32) -> TangramPenroseReport {
    let mut single_area: usize = 0;
    let mut idx: usize = 0;
    while idx < TANGRAM_PIECES_PER_CLAUSE {
        single_area += tangram_piece_area_units(idx);
        idx += 1;
    }
    let dual_area = single_area * 2;

    let h00: f32 = 1.0;
    let h01: f32 = shear_k;
    let h10: f32 = 0.0;
    let h11: f32 = 1.0;
    let parallelogram_shear_det = h00 * h11 - h01 * h10;

    let rad_72 = 72.0_f32.to_radians();
    let rad_36 = 36.0_f32.to_radians();
    let thick_rhombus_area = rad_72.sin();
    let thin_rhombus_area = rad_36.sin();
    let penrose_rhombus_area_ratio = thick_rhombus_area / thin_rhombus_area;

    let rad_santos = SANTOS_PENROSE_DEG.to_radians();
    let cos_s = rad_santos.cos();
    let sin_s = rad_santos.sin();

    let mut projected_field_coords: Vec<f32> = Vec::with_capacity(TANGRAM_PIECES_PER_CLAUSE * 2);
    let mut slot: usize = 0;
    while slot < TANGRAM_PIECES_PER_CLAUSE * 2 {
        let tok = *svo_tokens.get(slot).unwrap_or(&0) as f32;
        let area_scale = tangram_piece_area_units(slot) as f32;
        let x = tok * cos_s + area_scale * GOLDEN_RATIO_PHI;
        let y = tok * sin_s;
        let sheared_x = if (slot % TANGRAM_PIECES_PER_CLAUSE) == 4 {
            h00 * x + h01 * y
        } else {
            x
        };
        projected_field_coords.push(sheared_x);
        slot += 1;
    }

    TangramPenroseReport {
        single_clause_area_units: single_area,
        dual_clause_stalk_units: dual_area,
        parallelogram_shear_det,
        penrose_rhombus_area_ratio,
        projected_field_coords,
    }
}