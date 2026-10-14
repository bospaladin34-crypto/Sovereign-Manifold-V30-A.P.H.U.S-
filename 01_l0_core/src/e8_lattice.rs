pub const E8_DIM: usize = 8;

pub struct ConwaySloaneE8;

impl ConwaySloaneE8 {
    /// Snaps an 8D continuous vector onto the closest root point in the E8 root lattice
    /// Enforces strict Zero-Square-Bracket indexing via iterators and pattern matching.
    pub fn snap(x: &[f32; E8_DIM]) -> [i32; E8_DIM] {
        let mut r = [0i32; E8_DIM];
        let mut sum_r = 0i32;
        let mut diff_r = [0.0f32; E8_DIM];

        for (i, (&xi, ri)) in x.iter().zip(r.iter_mut()).enumerate() {
            let rounded = xi.round() as i32;
            *ri = rounded;
            sum_r += rounded;
            if let Some(d) = diff_r.get_mut(i) {
                *d = (xi - rounded as f32).abs();
            }
        }

        if sum_r % 2 != 0 {
            let mut max_idx = 0;
            let mut max_d = -1.0f32;
            for (idx, &d) in diff_r.iter().enumerate() {
                if d > max_d {
                    max_d = d;
                    max_idx = idx;
                }
            }
            if let Some(target) = r.get_mut(max_idx) {
                let orig = x.get(max_idx).copied().unwrap_or(0.0);
                if orig > *target as f32 {
                    *target += 1;
                } else {
                    *target -= 1;
                }
            }
        }

        let mut h = [0i32; E8_DIM];
        let mut sum_h = 0i32;
        let mut diff_h = [0.0f32; E8_DIM];

        for (i, (&xi, hi)) in x.iter().zip(h.iter_mut()).enumerate() {
            let shifted = xi - 0.5;
            let rounded = shifted.round() as i32;
            *hi = rounded;
            sum_h += rounded;
            if let Some(d) = diff_h.get_mut(i) {
                *d = (shifted - rounded as f32).abs();
            }
        }

        if sum_h % 2 != 0 {
            let mut max_idx = 0;
            let mut max_d = -1.0f32;
            for (idx, &d) in diff_h.iter().enumerate() {
                if d > max_d {
                    max_d = d;
                    max_idx = idx;
                }
            }
            if let Some(target) = h.get_mut(max_idx) {
                let orig = x.get(max_idx).copied().unwrap_or(0.0) - 0.5;
                if orig > *target as f32 {
                    *target += 1;
                } else {
                    *target -= 1;
                }
            }
        }

        let mut dist_r = 0.0f32;
        let mut dist_h = 0.0f32;
        for (i, &xi) in x.iter().enumerate() {
            let r_coord = r.get(i).copied().unwrap_or(0) as f32;
            let h_coord = h.get(i).copied().unwrap_or(0) as f32 + 0.5;
            dist_r += (xi - r_coord) * (xi - r_coord);
            dist_h += (xi - h_coord) * (xi - h_coord);
        }

        if dist_r <= dist_h {
            r
        } else {
            let mut res = [0i32; E8_DIM];
            for (ri, hi) in res.iter_mut().zip(h.iter()) {
                *ri = (hi * 2) + 1;
            }
            res
        }
    }
}