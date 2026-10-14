// 01_l0_core/src/modular_braid_sl2z.rs
// v30 Track 17: Modular Group PSL_2(Z) / SL_2(Z) <-> Artin B_3 Integer Shear-Braid Compiler
// sigma_1 -> [[1, 1], [0, 1]], sigma_2 -> [[1, 0], [-1, 1]]
// Zero-Square-Bracket Rust Invariant Enforced

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Mat2Z {
    pub a: i64,
    pub b: i64,
    pub c: i64,
    pub d: i64,
}

pub struct ModularBraidReport {
    pub lhs_s1_s2_s1: Mat2Z,
    pub rhs_s2_s1_s2: Mat2Z,
    pub yang_baxter_verified: bool,
    pub central_cube_matrix: Mat2Z,
    pub psl2z_identity_verified: bool,
    pub compiled_word_det: i64,
}

impl Mat2Z {
    #[inline]
    pub fn identity() -> Self {
        Mat2Z { a: 1, b: 0, c: 0, d: 1 }
    }

    #[inline]
    pub fn sigma1() -> Self {
        Mat2Z { a: 1, b: 1, c: 0, d: 1 }
    }

    #[inline]
    pub fn sigma1_inv() -> Self {
        Mat2Z { a: 1, b: -1, c: 0, d: 1 }
    }

    #[inline]
    pub fn sigma2() -> Self {
        Mat2Z { a: 1, b: 0, c: -1, d: 1 }
    }

    #[inline]
    pub fn sigma2_inv() -> Self {
        Mat2Z { a: 1, b: 0, c: 1, d: 1 }
    }

    #[inline]
    pub fn mul(self, rhs: Mat2Z) -> Mat2Z {
        Mat2Z {
            a: self.a * rhs.a + self.b * rhs.c,
            b: self.a * rhs.b + self.b * rhs.d,
            c: self.c * rhs.a + self.d * rhs.c,
            d: self.c * rhs.b + self.d * rhs.d,
        }
    }

    #[inline]
    pub fn det(self) -> i64 {
        self.a * self.d - self.b * self.c
    }
}

pub fn verify_modular_braid_representation(generators: &Vec<i8>) -> ModularBraidReport {
    let s1 = Mat2Z::sigma1();
    let s2 = Mat2Z::sigma2();
    let lhs_s1_s2_s1 = s1.mul(s2).mul(s1);
    let rhs_s2_s1_s2 = s2.mul(s1).mul(s2);
    let yang_baxter_verified = lhs_s1_s2_s1 == rhs_s2_s1_s2 && lhs_s1_s2_s1.det() == 1;

    let s1_s2 = s1.mul(s2);
    let central_cube_matrix = s1_s2.mul(s1_s2).mul(s1_s2);
    let psl2z_identity_verified = central_cube_matrix == Mat2Z { a: -1, b: 0, c: 0, d: -1 };

    let mut acc = Mat2Z::identity();
    for g in generators.iter() {
        let step = match *g {
            1 => Mat2Z::sigma1(),
            -1 => Mat2Z::sigma1_inv(),
            2 => Mat2Z::sigma2(),
            -2 => Mat2Z::sigma2_inv(),
            _ => if *g > 0 { Mat2Z::sigma1() } else { Mat2Z::sigma1_inv() },
        };
        acc = acc.mul(step);
    }

    ModularBraidReport {
        lhs_s1_s2_s1,
        rhs_s2_s1_s2,
        yang_baxter_verified,
        central_cube_matrix,
        psl2z_identity_verified,
        compiled_word_det: acc.det(),
    }
}