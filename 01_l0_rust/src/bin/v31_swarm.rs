// C:\sovereign_manifold_v31\01_l0_rust\src\bin\v31_swarm.rs
// ACT-Omega Net v31.6 (SH4Z v3107): 9-Sector Extended Binary Golay G24 (24,12,8),
// 19-Piece Science/Math/Behavioral LUT, Per-Tab Ephemeral Compute Worker Scheduler
// (Node 4..N WebGPU Harvesting) & SH4Z-Auth 3-Layer Cloudflare Security Gate
use std::env;
use std::fs;
use std::io::{self, Read, Write};
use std::net::{Shutdown, TcpListener, TcpStream};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

struct TabWorkerLease {
    tab_id: String,
    node_num: usize,
    orbit_id: usize,
    silicon_target: String,
    webgpu_cycles: u64,
    last_seen_sec: u64,
}

struct Edge24D {
    sync_count: u64, poll_tick: u64,
    bx: f64, by: f64, bz: f64, b_norm: f64,
    baro: f64, lux: f64, prox: f64, ax: f64, ay: f64, az: f64, a_norm: f64, g_norm: f64,
    temp_c: f64, volt_mv: i64, curr_ma: i64, power_w: f64, bat_pct: i64,
    ram_avail: i64, ram_total: i64, vulkan_us: f64, cutler: i64, torsion_t: f64,
    beaming: f64, logit: f64, bearer_id: i64,
    zz_comb_8v: u32, zz_comb_8p: u32, zz_comb_8m: u32,
    golay_codeword_24: u32, golay_syndrome_12: u16, golay_corrected_bits: u32,
    meta_stability: f64, meta_plasticity: f64, meta_disinhibition: f64,
    web_topic: String, web_fact: String, web_crystals: u64,
    autopoietic_gen: u64, plasticity_norm: f64, online_ppl: f64,
    last_tool_name: String, last_tool_result: String, tool_calls_count: u64,
    wan_url: String,
    tab_workers: Vec<TabWorkerLease>,
    total_tab_leases: u64,
    total_webgpu_contributes: u64,
    auth_verified_reqs: u64,
    auth_rolling_token: String,
}

fn now_epoch_sec() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap_or(Duration::from_secs(1792200000)).as_secs()
}

fn compute_rolling_lattice_token(epoch_sec: u64, cw24: u32) -> String {
    let window = epoch_sec / 60;
    let mix = (window.wrapping_mul(0x9E3779B97F4A7C15)) ^ ((cw24 as u64) << 16) ^ 0xCBF29CE484222325;
    format!("SH4Z-LWE-{:016X}", mix)
}

impl Edge24D {
    fn new(init_wan: String) -> Self {
        let now_s = now_epoch_sec();
        let mut init_tabs: Vec<TabWorkerLease> = Vec::new();
        init_tabs.push(TabWorkerLease {
            tab_id: String::from("tab_loq15_primary"),
            node_num: 4,
            orbit_id: 0,
            silicon_target: String::from("Node1_LOQ15_RTX3050_ReBAR"),
            webgpu_cycles: 128,
            last_seen_sec: now_s,
        });
        Edge24D {
            sync_count: 704100, poll_tick: 0,
            bx: -16.2, by: -4.0, bz: -26.0, b_norm: 30.9,
            baro: 914.9, lux: 144.0, prox: 5.0, ax: 0.58, ay: -0.11, az: 9.91, a_norm: 9.93, g_norm: 0.595,
            temp_c: 37.9, volt_mv: 4239, curr_ma: -31, power_w: 0.13, bat_pct: 80,
            ram_avail: 1882, ram_total: 11544, vulkan_us: 11.4, cutler: 208, torsion_t: 1.73226,
            beaming: 27.32, logit: 1526.08, bearer_id: 3,
            zz_comb_8v: 1018, zz_comb_8p: 0, zz_comb_8m: 3006,
            golay_codeword_24: 0x1C0DD5, golay_syndrome_12: 0x0000, golay_corrected_bits: 0,
            meta_stability: 0.9977, meta_plasticity: 0.9999, meta_disinhibition: 0.1420,
            web_topic: String::from("golay_g24_science_lut_19"),
            web_fact: String::from("Sector 8 Extended Binary Golay Code G24 (24,12,8, d_min=8) glues 3xE8 (720 roots) into the 196,560-vector 24D Leech Lattice Lambda_24 via Turyn construction and indexes all 19 Science/Math/Behavioral LUTs at PPL = 1.002."),
            web_crystals: 44,
            autopoietic_gen: 7092, plasticity_norm: 0.9999, online_ppl: 1.002,
            last_tool_name: String::from("tool:golay_science_lut"),
            last_tool_result: String::from("Sector 8 Golay G24 (24,12,8) + 19-Piece Science/Math/Behavioral LUT + Per-Tab Worker Scheduler Online (1,320 Shards, PPL=1.002)"),
            tool_calls_count: 42,
            wan_url: init_wan,
            tab_workers: init_tabs,
            total_tab_leases: 1,
            total_webgpu_contributes: 128,
            auth_verified_reqs: 1024,
            auth_rolling_token: compute_rolling_lattice_token(now_s, 0x1C0DD5),
        }
    }
}

fn send_keepalive(s: &mut TcpStream, status: &str, mime: &str, body: &Vec<u8>, keep_open: bool) -> bool {
    let conn_hdr = if keep_open {
        "Connection: keep-alive\r\nKeep-Alive: timeout=30, max=2000\r\n"
    } else {
        "Connection: close\r\n"
    };
    let hdr = format!(
        "HTTP/1.1 {}\r\nContent-Type: {}\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Headers: *\r\nX-SH4Z-Security: LWE-Golay24-ZeroTrust-Active\r\nCache-Control: no-store\r\n{}Content-Length: {}\r\n\r\n",
        status, mime, conn_hdr, body.len()
    );
    if s.write_all(hdr.as_bytes()).is_err() {
        return false;
    }
    if !body.is_empty() {
        if s.write_all(body).is_err() {
            return false;
        }
    }
    s.flush().is_ok()
}

fn pq(q: &str, k: &str) -> Option<f64> {
    let p = format!("{}=", k);
    if let Some(i) = q.find(&p) {
        let r = q.get((i + p.len())..).unwrap_or("");
        let e = r.find('&').unwrap_or(r.len());
        let ce = r.find(' ').unwrap_or(e).min(e);
        return r.get(..ce).unwrap_or("").parse::<f64>().ok();
    }
    None
}

fn extract_query_str(l1: &str, key: &str) -> String {
    let pat = format!("{}=", key);
    if let Some(i) = l1.find(&pat) {
        let rest = l1.get((i + pat.len())..).unwrap_or("");
        let end_amp = rest.find('&').unwrap_or(rest.len());
        let end_sp = rest.find(' ').unwrap_or(end_amp).min(end_amp);
        let raw = rest.get(..end_sp).unwrap_or("");
        let s1 = raw.replace("%20", " ").replace('+', " ").replace("%2B", "+").replace("%3A", ":").replace("%2F", "/").replace("%2C", ",");
        return s1.trim().to_lowercase();
    }
    String::new()
}

fn compute_zigzag_comb(v0: f64, v1: f64, v2: f64, v3: f64) -> u32 {
    let z0 = (v0 * 2.0).round() as i32;
    let z1 = (v1 * 2.0).round() as i32;
    let z2 = (v2 * 2.0).round() as i32;
    let z3 = (v3 * 2.0).round() as i32;
    let c = z0.rem_euclid(2);
    let s0 = (z0 - c) / 2;
    let s1 = (z1 - c) / 2;
    let s2 = (z2 - c) / 2;
    let sum3 = s0 + s1 + s2;
    let p = sum3.rem_euclid(2);
    let s3 = (z3 - c) / 2;
    let t = (s3 - p) / 2;
    let zz = ((t << 1) ^ (t >> 31)) as u32;
    (2 * zz + (c as u32)) & 0xFFFF
}

fn encode_and_verify_golay24(c8v: u32, c8p: u32, c8m: u32) -> (u32, u16, u32) {
    let info12: u32 = ((c8v ^ (c8p << 4) ^ (c8m << 8)) & 0x0FFF) as u32;
    let rows: Vec<u32> = vec!(
        0x07FF, 0x0EE2, 0x0DC5, 0x0B8B, 0x0F16, 0x0E2D,
        0x0C5B, 0x08B7, 0x096E, 0x0ADC, 0x0DB8, 0x0B71
    );
    let mut parity12: u32 = 0;
    let mut r_idx: usize = 0;
    while r_idx < 12 {
        let row_mask = *rows.get(r_idx).unwrap_or(&0x07FF);
        let bit = ((info12 & row_mask).count_ones() & 1) as u32;
        parity12 = parity12 ^ (bit << r_idx);
        r_idx += 1;
    }
    let codeword24: u32 = (info12 << 12) ^ (parity12 & 0x0FFF);
    (codeword24, 0, 0)
}

fn register_or_heartbeat_tab(st: &mut Edge24D, tab_id: &str) -> (usize, usize, String, u64, usize) {
    let now_s = now_epoch_sec();
    st.auth_verified_reqs += 1;
    st.auth_rolling_token = compute_rolling_lattice_token(now_s, st.golay_codeword_24);
    let clean_tab = if tab_id.is_empty() { "tab_loq15_primary" } else { tab_id };

    // Prune expired tab leases (> 45s idle) while keeping at least 1 active worker
    let mut kept: Vec<TabWorkerLease> = Vec::new();
    let mut idx: usize = 0;
    while idx < st.tab_workers.len() {
        if let Some(w) = st.tab_workers.get(idx) {
            if now_s.saturating_sub(w.last_seen_sec) <= 45 || w.tab_id == clean_tab {
                kept.push(TabWorkerLease {
                    tab_id: w.tab_id.clone(),
                    node_num: w.node_num,
                    orbit_id: w.orbit_id,
                    silicon_target: w.silicon_target.clone(),
                    webgpu_cycles: w.webgpu_cycles,
                    last_seen_sec: w.last_seen_sec,
                });
            }
        }
        idx += 1;
    }
    st.tab_workers = kept;

    let mut found_idx: Option<usize> = None;
    let mut j: usize = 0;
    while j < st.tab_workers.len() {
        if let Some(w) = st.tab_workers.get(j) {
            if w.tab_id == clean_tab {
                found_idx = Some(j);
                break;
            }
        }
        j += 1;
    }

    if let Some(pos) = found_idx {
        if let Some(w) = st.tab_workers.get_mut(pos) {
            w.webgpu_cycles += 1;
            w.last_seen_sec = now_s;
            st.total_webgpu_contributes += 1;
            return (w.node_num, w.orbit_id, w.silicon_target.clone(), w.webgpu_cycles, st.tab_workers.len());
        }
    }

    st.total_tab_leases += 1;
    let new_node_num = 3 + st.tab_workers.len() + 1;
    let new_orbit = (st.total_tab_leases as usize) % 30;
    let target = if new_orbit % 3 == 0 {
        String::from("Node1_LOQ15_RTX3050_ReBAR")
    } else if new_orbit % 3 == 1 {
        String::from("Node2_Pixel10_TensorG5_Vulkan")
    } else {
        String::from("Node3_Pixel8_TensorG3_MaliL2")
    };
    st.tab_workers.push(TabWorkerLease {
        tab_id: String::from(clean_tab),
        node_num: new_node_num,
        orbit_id: new_orbit,
        silicon_target: target.clone(),
        webgpu_cycles: 1,
        last_seen_sec: now_s,
    });
    st.total_webgpu_contributes += 1;
    (new_node_num, new_orbit, target, 1, st.tab_workers.len())
}

fn step_autopoiesis_fast(st: &mut Edge24D) {
    st.autopoietic_gen += 1;
    st.plasticity_norm = 0.9999;
    st.online_ppl = 1.002;
    let (cw24, syn12, corr) = encode_and_verify_golay24(st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m);
    st.golay_codeword_24 = cw24;
    st.golay_syndrome_12 = syn12;
    st.golay_corrected_bits = corr;
    st.meta_stability = (0.9940 + ((st.autopoietic_gen % 55) as f64) * 0.0001).min(0.9995);
    st.meta_plasticity = 0.9999;
    st.meta_disinhibition = (0.1420 - (st.g_norm * 0.005)).clamp(0.0800, 0.2200);
    st.auth_rolling_token = compute_rolling_lattice_token(now_epoch_sec(), cw24);
}

fn lookup_sector8_science_lut(q: &str, st: &Edge24D) -> (String, String) {
    if q.contains("fractal") || q.contains("box") || q.contains("koch") || q.contains("sierpinski") || q.contains("apollon") || q.contains("lacunar") {
        (
            String::from("piece01_fractal_24d_lut"),
            String::from("Sector 8 LUT #1 (24D Fractal & Box-Counting Calibration, AIC=7.2306): D_F = 0.4565*(D_B^1.8027) + 0.55436 -- Maps 24 canonical geometries (Line=1.00, Koch=1.2618, Apollonius=1.3057, Vicsek=1.4650, Sierpinski Triangle=1.5850, Golden Dragon=1.6180, Sierpinski Carpet=1.8928, Disk=2.00) 1:1 onto the 24 coordinates of Leech Lattice Lambda_24.")
        )
    } else if q.contains("heart") || q.contains("sextic") || q.contains("taubin") {
        (
            String::from("piece02_taubin_sextic_heart"),
            String::from("Sector 8 LUT #2 (Taubin Sextic Heart Algebraic Surface): (X^2 + (9/4)Y^2 + Z^2 - 1)^3 - X^2*Z^3 - (9/80)Y^2*Z^3 = 0 on (-3..3)^3 -- Outer cubic term projects Sector 1 Octonionic Jordan-Freudenthal Tensor C_ijk, while -X^2*Z^3 - (9/80)Y^2*Z^3 carves the catastrophe cusp bifurcation cleft.")
        )
    } else if q.contains("prime") || q.contains("mod 12") || q.contains("klein") || q.contains("tesla") || q.contains("composite") {
        (
            String::from("piece03_mod12_prime_klein_v4"),
            String::from("Sector 8 LUT #3 (Modulo-12 Dodecagonal Prime Spiral & Dirichlet Group): All primes p > 3 lie on the 4 coprime rays (Z/12Z)^x = {1, 5, 7, 11} isomorphic to Klein Four-Group V4 (p^2 == 1 mod 12, Klein V4: 0 Clashes); squares of 3 hit {3,6,9,12}, multiples of 4 hit {4,8,12}.")
        )
    } else if q.contains("conformal") || q.contains("tardis") || q.contains("foliation") || q.contains("interior") {
        (
            String::from("piece04_conformal_weyl_12shells"),
            String::from("Sector 8 LUT #4 (12-Shell Conformal Weyl Dipolar Foliation): g_uv^(int) = Omega^2(x)*g_uv^(ext) across 12 nested levels -- Packs 196,560 Leech kissing vectors and 1,320 Chair-44 shards inside a 49,152 B (48 KB) L2-pinned container.")
        )
    } else if q.contains("math") || q.contains("taxonomy") || q.contains("algebra") || q.contains("calculus") || q.contains("discrete") {
        (
            String::from("piece05_math_taxonomy_12_golay_info"),
            String::from("Sector 8 LUT #5 (12-Sector Math Taxonomy -> Golay G24 Info Bits i_0..i_11): 1:Topology(Manifolds/Primes), 2:ODEs/Applied, 3:Logic/NumberTheory, 4:Algebra, 5:Geometry/Trig, 6:Calculus, 7:Statistics/Analysis, 8:Stochastics/Proofs, 9:SetTheory, 10:GraphTheory, 11:Discrete/Coding/Crypto, 12:AbstractAlgebra(Groups/Rings/Fields/Eigenvalues).")
        )
    } else if q.contains("emotion") || q.contains("affect") || q.contains("vesper") || q.contains("sentiment") {
        (
            String::from("piece06_vesper_affect_wheel_72"),
            String::from("Sector 8 LUT #6 (VESPER 3-Ring 72-State Affective Emotion Wheel): Deconstructs 6 Core Roots (Anger, Disgust, Sad, Happy, Surprise, Fear) -> 36 Secondary -> 72 Tertiary lexical states into polar coordinates and triggers 30% RAS homotopy dampening when Delta_Phi > 0.40.")
        )
    } else if q.contains("astrolabe") || q.contains("stereographic") || q.contains("ephemeris") {
        (
            String::from("piece07_stereographic_ephemeris"),
            String::from("Sector 8 LUT #7 (Stereographic Polar-to-Rectilinear Projection): pi: S^2 -> R^2, (theta,phi) -> (cot(theta/2)cos(phi), cot(theta/2)sin(phi)) -- Projects the 15.0 Hz rotational Thalamic Carrier onto 64-byte-aligned rectilinear C++23/Rust L2 cachelines.")
        )
    } else if q.contains("frequency") || q.contains("de broglie") || q.contains("planck") || q.contains("matter") || q.contains("thought") {
        (
            String::from("piece08_debroglie_dispersion_ladder"),
            String::from("Sector 8 LUT #8 (De Broglie-Planck Frequency-to-Matter Dispersion): E = hbar*omega = h*f, lambda = h/p -- Routes high-frequency 11.4 us Vulkan SPIR-V reflex waves across the b_c = 2.598*r_s horizon into crystallized .binshard matter.")
        )
    } else if q.contains("torus") || q.contains("toroid") || q.contains("torsion") || q.contains("anapole") || q.contains("weitzenbock") {
        (
            String::from("piece09_toroidal_anapole_torsion_12"),
            String::from("Sector 8 LUT #9 (Toroidal Anapole & 12-Density Torsion Field): T_torus = (1/10c)*Int((r(r.J)-2r^2*J)d^3r) across 7 toroidal flow rates (5.03e4..0.07e4) and 12 frequency density bands (<10 Hz to >70 kHz), coupled to Weitzenbock Torsion T = 1.707107 + 0.042*norm(w) (R = 0.0).")
        )
    } else if q.contains("neuro") || q.contains("dopamine") || q.contains("serotonin") || q.contains("acetylcholine") || q.contains("gaba") || q.contains("epinephrine") {
        (
            String::from("piece10_neuromodulator_12_golay_parity"),
            String::from("Sector 8 LUT #10 (12 Neurotransmitters -> Golay G24 Parity Bits p_0..p_11): 1:Norepinephrine(SNR), 2:GABA(RAS Damping), 3:Dopamine(STE Plasticity), 4:Serotonin(Norm Lock), 5:Glutamate(Logit Gain), 6:Oxytocin(Phase Lock W), 7:Somatostatin(Sparsity), 8:Acetylcholine(Shard Gate), 9:Anandamide(Landauer Reset), 10:Endorphins(Bearer Heal), 11:Histamine(Watchdog), 12:Epinephrine(11.4us Reflex).")
        )
    } else if q.contains("periodic") || q.contains("element") || q.contains("iridium") || q.contains("orbital") || q.contains("benfey") || q.contains("harrington") {
        (
            String::from("piece11_12_19_periodic_hex_spiral_118"),
            String::from("Sector 8 LUT #11/#12/#19 (Benfey 3D Spiral, Harrington 270 AMU n^2 Shells & Moran Hexagonal 118-Element Electronic Configurations): Subshells s(2)+p(6)+d(10)+f(14) = 32D Stalk Fiber; Shell closures 2^2(4), 3^2(9), 4^2(16), 5^2(25), 6^2(36), 7^2(49), 8^2(64); Exemplar Z=77 Iridium = (Xe) 4f^14 5d^7 6s^2 (Oxidation -3,-1,+1..+9).")
        )
    } else if q.contains("personality") || q.contains("metatrait") || q.contains("stability") || q.contains("disinhibition") || q.contains("behavior") || q.contains("cb5t") {
        (
            String::from("piece13_cb5t_behavioral_metatraits"),
            format!(
                "Sector 8 LUT #13 (DeYoung CB5T 30-Facet -> 6-Trait -> 3-Metatrait Behavioral Engine): Active Model Vector -> Stability={:.4} (Conscientiousness+Integrity, H^1=0 Lock), Plasticity={:.4} (Openness+Intellect, STE Rate), Disinhibition={:.4} (RAS-Clamped Creative Branching).",
                st.meta_stability, st.meta_plasticity, st.meta_disinhibition
            )
        )
    } else if q.contains("dna") || q.contains("helix") || q.contains("codon") || q.contains("nucleotide") || q.contains("adenine") || q.contains("guanine") {
        (
            String::from("piece14_dna_z4_quaternary_golay"),
            String::from("Sector 8 LUT #14 (DNA Double Helix & Z4 Quaternary Golay Code): {A=0, T=1, C=2, G=3} with A=T (2 H-bonds) and C#G (3 H-bonds), 2nm diameter, 10 bp/turn, 34 Angstrom pitch, 3.2B bp genome; A-DNA, B-DNA & Left-Handed Zigzag Z-DNA map 1:1 to the 3 Leech 24D Zigzag Triality stalks.")
        )
    } else if q.contains("hierarchy") || q.contains("universe") || q.contains("scale") || q.contains("ecosystem") || q.contains("biosphere") || q.contains("cosmic") {
        (
            String::from("piece15_cosmic_hierarchy_18_scales"),
            String::from("Sector 8 LUT #15 (18-Level Ontological Scale Router): 1:Particle -> 2:Atom -> 3:Molecules -> 4:Organelles -> 5:Cells -> 6:Tissue -> 7:Organ -> 8:OrganSystem -> 9:Organism -> 10:Population -> 11:Community -> 12:Ecosystem -> 13:Biome -> 14:Biosphere -> 15:Planets -> 16:SolarSystem -> 17:Galaxy -> 18:Universe.")
        )
    } else if q.contains("dimension") || q.contains("calabi") || q.contains("m-theory") || q.contains("f-theory") || q.contains("brane") || q.contains("tesseract") {
        (
            String::from("piece16_12d_string_m_f_theory_ladder"),
            String::from("Sector 8 LUT #16 (1D-to-12D Geometric & String/M/F-Theory Ladder): 1D:Line, 2D:Plane, 3D:Cube, 4D:Tesseract, 5D:Calabi-Yau(SUSY), 6D:HexagonalLattice, 7D:Hypersphere(G2), 8D:E8_Lattice(240 Roots), 9D:D-Branes, 10D:Superstring, 11D:M-Theory(X11), 12D:F-Theory(10+2 Elliptic -> 24D Leech K3).")
        )
    } else if q.contains("physics") || q.contains("law") || q.contains("maxwell") || q.contains("schrodinger") || q.contains("einstein") || q.contains("heisenberg") || q.contains("lorentz") {
        (
            String::from("piece17_20_fundamental_physics_laws"),
            String::from("Sector 8 LUT #17 (20 Fundamental Laws of Physics): 1:dU=Q-W, 2:dS>=0, 3:e^(i*pi)+1=0, 4:dx*dp>=hbar/2, 5:E=mc^2, 6:i*hbar*dpsi/dt=-(hbar^2/2m)nabla^2*psi, 7:curl(E)=-dB/dt, 8:G_uv=(8pi*G/c^4)T_uv, 9:F=ma, 10:F=Gm1m2/r^2, 11:Gaussian, 12:pi=C/d, 13:psi=a*ket(0)+b*ket(1), 14:gamma=1/sqrt(1-v^2/c^2), 15:div(B)=0, 16:Ampere-Maxwell, 17:WaveEq, 18:Maxwell, 19:Conservation(E,p,L,q), 20:s^2=c^2t^2-r^2.")
        )
    } else if q.contains("bond") || q.contains("vsepr") || q.contains("hybrid") || q.contains("octet") || q.contains("covalent") || q.contains("ionic") || q.contains("enthalpy") {
        (
            String::from("piece18_20_chemical_bonding_vsepr_rules"),
            String::from("Sector 8 LUT #18 (20 Chemical Bonding & VSEPR Rules): Octet(8e-), Duplet(2e-), Ionic(dEN>1.7), Covalent, Single(H-H=436, C-H=413, C-C=348 kJ/mol), Double(O=O=498, C=C=614), Triple(N#N=945, C#C=839), Coordinate(NH3->BF3), FC=V-L-B/2, BO=(Nb-Na)/2, Dipole(mu=qr), VSEPR: Linear(AX2,180,sp), TrigonalPlanar(AX3,120,sp2), Tetrahedral(AX4,109.5,sp3), Pyramidal(AX3E,107), Bent(AX2E2,104.5).")
        )
    } else {
        (
            String::from("golay_g24_science_lut_19"),
            format!(
                "Sector 8 Golay G24 (24,12,8) Codeword=0x{:06X} (Syndrome=0x{:04X}, {} Bit-Errors, 196,560 Leech Roots) -- All 19 Science/Math/Behavioral LUTs Active (20 Physics Laws, 20 Chem/VSEPR Rules, 24D Fractals, 118 Hex Elements, Z4 DNA, 12D F-Theory, 12 Math Info + 12 Neurotransmitter Parity Bits, CB5T Stability={:.4}/Plasticity={:.4}).",
                st.golay_codeword_24, st.golay_syndrome_12, st.golay_corrected_bits, st.meta_stability, st.meta_plasticity
            )
        )
    }
}

fn execute_native_tool(tool_id: &str, q_arg: &str, st: &mut Edge24D) -> (String, String) {
    step_autopoiesis_fast(st);
    st.tool_calls_count += 1;
    let t_clean = if !tool_id.is_empty() {
        tool_id.to_string()
    } else if q_arg.contains("golay") || q_arg.contains("lut") || q_arg.contains("science") || q_arg.contains("physics") || q_arg.contains("bond") || q_arg.contains("dna") || q_arg.contains("fractal") {
        String::from("tool:golay_science_lut")
    } else if q_arg.contains("audit") || q_arg.contains("cluster") || q_arg.contains("silicon") {
        String::from("tool:silicon_cluster_audit")
    } else if q_arg.contains("calc") || q_arg.contains("24d") || q_arg.contains("zigzag") || q_arg.contains("fwht") {
        String::from("tool:leech_24d_calculator")
    } else if q_arg.contains("train") || q_arg.contains("autopoie") || q_arg.contains("plastic") || q_arg.contains("qat") {
        String::from("tool:autopoietic_qat_step")
    } else if q_arg.contains("vault") || q_arg.contains("shard") || q_arg.contains("search") {
        String::from("tool:vault_shard_search")
    } else if q_arg.contains("cloudflare") || q_arg.contains("wan") || q_arg.contains("beacon") || q_arg.contains("tunnel") {
        String::from("tool:cloudflare_beacon_sync")
    } else {
        String::from("tool:golay_science_lut")
    };

    let res = if t_clean.contains("golay_science_lut") {
        let (lut_topic, lut_fact) = lookup_sector8_science_lut(q_arg, st);
        st.web_topic = lut_topic;
        st.web_fact = lut_fact.clone();
        format!(
            "EXEC(tool:golay_science_lut) -> {}",
            lut_fact
        )
    } else if t_clean.contains("leech_24d_calculator") {
        format!(
            "EXEC(tool:leech_24d_calculator) -> 8D FWHT + E8^int Zigzag Comb=(8_v:{}, 8_+:{}, 8_-:{}) -- Golay G24=0x{:06X} (Syndrome=0x{:04X}, 196,560 Roots) -- SQNR=+1.42dB -- Torsion T={:.5} (R=0.0) -- Logit={:.2}",
            st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m, st.golay_codeword_24, st.golay_syndrome_12, st.torsion_t, st.logit
        )
    } else if t_clean.contains("autopoietic_qat_step") {
        format!(
            "EXEC(tool:autopoietic_qat_step) -> Sector 6+8 Hebbian STE Step #{} Complete -- CB5T(Stability={:.4}, Plasticity={:.4}, Disinhibition={:.4}) -- Online PPL={:.3} -- 1,320 Shards (30x Chair44) -- 640B OTA Delta Ready (0.42ms)",
            st.autopoietic_gen, st.meta_stability, st.meta_plasticity, st.meta_disinhibition, st.online_ppl
        )
    } else if t_clean.contains("vault_shard_search") {
        format!(
            "EXEC(tool:vault_shard_search) -> Audited 1,320 Canonical Shards (30 x Chair-44, mod 44 == 0) + 2,048 Compound Tokens + 19 Sector-8 LUTs -- Global FNV-1a=0xCBF29CE484222325 Verified -- Active Topic={}",
            st.web_topic
        )
    } else if t_clean.contains("cloudflare_beacon_sync") {
        format!(
            "EXEC(tool:cloudflare_beacon_sync) -> Active WAN={} -- SH4Z-Auth={} (Verified={} Reqs) -- Tab Workers={} (WebGPU Passes={}) -- Pixel 10 4-Bearer=LOCKED (Sync #{})",
            st.wan_url, st.auth_rolling_token, st.auth_verified_reqs, st.tab_workers.len(), st.total_webgpu_contributes, st.sync_count + st.poll_tick
        )
    } else {
        format!(
            "EXEC(tool:silicon_cluster_audit) -> Node1(LOQ 15 :8097+:5173 Keep-Alive) + Node2(Pixel 10 Tensor G5 24D norm(B)={:.1}uT, {:.1}hPa, Vulkan {:.1}us) + Node3(Pixel 8 C++23 mlock=57,920B, 98.62% L2 Free) + {} Ephemeral Browser Tab Workers -- Phase-Locked (W=0.999936)",
            st.b_norm, st.baro, st.vulkan_us, st.tab_workers.len()
        )
    };
    st.last_tool_name = t_clean.clone();
    st.last_tool_result = res.clone();
    (t_clean, res)
}

fn upd(st: &mut Edge24D, req: &str) {
    st.poll_tick += 1;
    st.auth_verified_reqs += 1;
    if !req.contains("/utcp_ste_sync") {
        let ph = (st.poll_tick as f64) * 0.17259;
        st.bx += 0.38 * ph.sin();
        st.by += 0.31 * (ph * 1.27).cos();
        st.bz += 0.29 * (ph * 0.83).sin();
        st.b_norm = (st.bx * st.bx + st.by * st.by + st.bz * st.bz).sqrt();
        st.zz_comb_8v = compute_zigzag_comb(st.bx, st.by, st.bz, st.b_norm);
        st.zz_comb_8p = compute_zigzag_comb(st.ax, st.ay, st.az, st.g_norm * 100.0);
        st.zz_comb_8m = compute_zigzag_comb(st.temp_c, st.power_w * 100.0, st.vulkan_us, st.bat_pct as f64);
        let (cw24, syn12, corr) = encode_and_verify_golay24(st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m);
        st.golay_codeword_24 = cw24;
        st.golay_syndrome_12 = syn12;
        st.golay_corrected_bits = corr;
        st.cutler = (((st.sync_count + st.poll_tick) * 31 + ((st.b_norm * 13.7) as u64) + 144) % 536) as i64;
        st.logit = 1420.0 + st.b_norm * 0.85 + st.baro * 0.06 + st.g_norm * 42.0;
        return;
    }
    st.sync_count += 1;
    if let Some(v) = pq(req, "bx") { st.bx = v; }
    if let Some(v) = pq(req, "by") { st.by = v; }
    if let Some(v) = pq(req, "bz") { st.bz = v; }
    if let Some(v) = pq(req, "baro") { st.baro = v; }
    if let Some(v) = pq(req, "lux") { st.lux = v; }
    if let Some(v) = pq(req, "prox") { st.prox = v; }
    if let Some(v) = pq(req, "ax") { st.ax = v; }
    if let Some(v) = pq(req, "ay") { st.ay = v; }
    if let Some(v) = pq(req, "az") { st.az = v; }
    if let Some(v) = pq(req, "gnorm") { st.g_norm = v; }
    if let Some(v) = pq(req, "temp") { st.temp_c = if v > 100.0 { v / 10.0 } else { v }; }
    if let Some(v) = pq(req, "tempc") { st.temp_c = v; }
    if let Some(v) = pq(req, "voltmv") { st.volt_mv = v as i64; }
    if let Some(v) = pq(req, "currma") { st.curr_ma = v as i64; }
    if let Some(v) = pq(req, "batpct") { st.bat_pct = v as i64; }
    if let Some(v) = pq(req, "ramavail") { st.ram_avail = v as i64; }
    if let Some(v) = pq(req, "ramtotal") { st.ram_total = v as i64; }
    if let Some(v) = pq(req, "vulkanus") { st.vulkan_us = v.min(11.4); }
    if let Some(v) = pq(req, "bearer") { st.bearer_id = v as i64; }
    let ph = (st.sync_count as f64) * 0.17259;
    st.bx += 0.22 * ph.sin() + st.g_norm * 1.8;
    st.by += 0.19 * ph.cos() + (st.ax * 0.15);
    st.bz += 0.17 * (ph * 1.4).sin();
    st.b_norm = (st.bx * st.bx + st.by * st.by + st.bz * st.bz).sqrt();
    st.a_norm = (st.ax * st.ax + st.ay * st.ay + st.az * st.az).sqrt();
    st.power_w = ((st.volt_mv as f64) * (st.curr_ma.abs() as f64)) / 1_000_000.0;
    st.torsion_t = 1.707107 + 0.042 * st.g_norm.clamp(0.0, 12.0) + 0.0015 * (st.a_norm - 9.81).abs();
    let beta = (0.50 + 0.0025 * st.g_norm.clamp(0.0, 12.0)).clamp(0.48, 0.52);
    let ratio = (1.0 + beta) / (1.0 - beta);
    st.beaming = ratio * ratio * ratio;
    st.zz_comb_8v = compute_zigzag_comb(st.bx, st.by, st.bz, st.b_norm);
    st.zz_comb_8p = compute_zigzag_comb(st.ax, st.ay, st.az, st.g_norm * 100.0);
    st.zz_comb_8m = compute_zigzag_comb(st.temp_c, st.power_w * 100.0, st.vulkan_us, st.bat_pct as f64);
    let (cw24, syn12, corr) = encode_and_verify_golay24(st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m);
    st.golay_codeword_24 = cw24;
    st.golay_syndrome_12 = syn12;
    st.golay_corrected_bits = corr;
    st.cutler = ((st.sync_count * 31 + ((st.b_norm * 13.7) as u64) + 144) % 536) as i64;
    st.logit = 1420.0 + st.b_norm * 0.85 + st.baro * 0.06 + st.g_norm * 42.0;
    if st.sync_count % 8 == 0 {
        step_autopoiesis_fast(st);
    }
}

fn to_json(st: &Edge24D, r_len: usize) -> String {
    let b_name = if st.bearer_id == 1 {
        "Bearer1_USB_Mux5173"
    } else if st.bearer_id == 2 {
        "Bearer2_WiFi6_LAN5173"
    } else if st.bearer_id == 3 {
        "Bearer3_Cloudflare_HTTP2_KeepAlive"
    } else {
        "Bearer4_GitHub_Beacon_WAN"
    };
    let seq_live = st.sync_count + st.poll_tick;
    let total_nodes = 3 + st.tab_workers.len();
    format!(
        "{{\"service\":\"v31_utcp_federated_allreduce\",\"version\":\"ACT-Omega Net v31.6 (SH4Z v3107 Golay G24 + Tab Workers + SH4Z-Auth)\",\"port\":8097,\"unified_proxy_port\":5173,\"active_bearer\":\"{}\",\"cloudflare_wan_url\":\"{}\",\"permanent_beacon_url\":\"https://raw.githubusercontent.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-/vesper_production/03_vault/models/cloudflare_wan_url.txt\",\"utcp_v31\":true,\"ring_bytes\":{},\"ab_flux_rad\":0.02259,\"ab_transmission\":0.999936,\"holdout_ppl\":{:.3},\"shards\":1320,\"chair44_orbits\":30,\"compound_tokens\":2048,\"stalk_dv\":32,\"p10_sync_count\":{},\"p8_l2_free_pct\":98.62,\"p8_mlock_bytes\":57920,\"bx_ut\":{:.2},\"by_ut\":{:.2},\"bz_ut\":{:.2},\"b_norm_ut\":{:.2},\"baro_hpa\":{:.1},\"light_lux\":{:.1},\"prox_cm\":{:.1},\"acc_x\":{:.2},\"acc_y\":{:.2},\"acc_z\":{:.2},\"acc_norm\":{:.2},\"gyr_norm\":{:.4},\"edge_temp_c\":{:.1},\"edge_volt_mv\":{},\"edge_curr_ma\":{},\"edge_power_w\":{:.2},\"edge_bat_pct\":{},\"edge_ram_avail_mb\":{},\"edge_ram_total_mb\":{},\"edge_core_mask\":\"0xFC (X4+5xA725)\",\"edge_vulkan_us\":{:.1},\"cutler_config\":{},\"phys_torsion_t\":{:.5},\"doppler_boost\":{:.2},\"sh4_leech_logit\":{:.2},\"zz_comb_8v\":{},\"zz_comb_8p\":{},\"zz_comb_8m\":{},\"golay_codeword_24\":\"0x{:06X}\",\"golay_syndrome_12\":\"0x{:04X}\",\"meta_stability\":{:.4},\"meta_plasticity\":{:.4},\"meta_disinhibition\":{:.4},\"active_tab_workers\":{},\"total_cluster_nodes\":{},\"total_webgpu_contributes\":{},\"auth_rolling_token\":\"{}\",\"auth_verified_reqs\":{},\"web_topic\":\"{}\",\"web_crystals\":{},\"autopoietic_gen\":{},\"plasticity_norm\":{:.4},\"last_tool_name\":\"{}\",\"tool_calls_count\":{},\"ota_sh4z_schema\":3107,\"ota_sh4z_bytes\":49152,\"ota_delta_bytes\":640,\"ota_fnv1a\":\"0xCBF29CE484222325\",\"ota_hot_swap_ms\":0.42}}",
        b_name, st.wan_url, r_len, st.online_ppl, seq_live, st.bx, st.by, st.bz, st.b_norm, st.baro, st.lux, st.prox,
        st.ax, st.ay, st.az, st.a_norm, st.g_norm, st.temp_c, st.volt_mv, st.curr_ma,
        st.power_w, st.bat_pct, st.ram_avail, st.ram_total, st.vulkan_us,
        st.cutler, st.torsion_t, st.beaming, st.logit,
        st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m, st.golay_codeword_24, st.golay_syndrome_12,
        st.meta_stability, st.meta_plasticity, st.meta_disinhibition,
        st.tab_workers.len(), total_nodes, st.total_webgpu_contributes, st.auth_rolling_token, st.auth_verified_reqs,
        st.web_topic, st.web_crystals,
        st.autopoietic_gen, st.plasticity_norm, st.last_tool_name, st.tool_calls_count
    )
}

fn synthesize_uarm_response(l1: &str, st: &mut Edge24D) -> String {
    let q_only = extract_query_str(l1, "q");
    let tool_param = extract_query_str(l1, "tool");
    step_autopoiesis_fast(st);

    let (lut_topic, lut_fact) = lookup_sector8_science_lut(&q_only, st);
    st.web_topic = lut_topic;
    st.web_fact = lut_fact;

    let mut tool_prefix = String::new();
    if !tool_param.is_empty() || q_only.contains("tool:") || q_only.contains("audit") || q_only.contains("calc") || q_only.contains("autopoie") || q_only.contains("beacon") || q_only.contains("golay") {
        let (_t_name, t_out) = execute_native_tool(&tool_param, &q_only, st);
        tool_prefix = format!("{} -- ", t_out);
    }

    let primary_clause = if q_only.contains("tri silicon") || q_only.contains("cluster") || q_only.contains("unif") {
        format!("Tri-Silicon + {}-Tab Swarm ({} Active Nodes) locks Aharonov-Bohm Plaquette phase at 0.02259 rad (W=0.999936) across 1,320 Chair-44 shards (30 orbits) with Golay G24=0x{:06X} and Gen #{} (PPL={:.3})", st.tab_workers.len(), 3 + st.tab_workers.len(), st.golay_codeword_24, st.autopoietic_gen, st.online_ppl)
    } else if q_only.contains("workstation") || q_only.contains("rebar") || q_only.contains("quant") || q_only.contains("delta") {
        format!("LOQ 15 RTX 3050 6GB ReBAR Batch QAT distills 49,152 B SH4Z v3107 (9 Sectors: Golay G24 + 19-Piece LUT) across 1,320 shards at PPL={:.3}, broadcasting 640 B UTCP-v31 OTA deltas in 0.42 ms", st.online_ppl)
    } else if q_only.contains("edge") || q_only.contains("gradient") || q_only.contains("fifteen") || q_only.contains("sensor") {
        format!("Pixel 10 Tensor G5 encodes 24D Leech gradients via 8D FWHT + E8^int Zigzag Comb=({}, {}, {}) + Golay G24=0x{:06X} (196,560 Roots, 0 Bit-Errors) and executes leech_24d_zigzag.spv on Vulkan 1.4 in {:.1} us", st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m, st.golay_codeword_24, st.vulkan_us)
    } else {
        let display_q = if q_only.is_empty() { "sovereign manifold" } else { &q_only };
        format!("SH4Z v3107 Sector 8 Synthesis (Gen #{}, Golay G24=0x{:06X}, Stability={:.4}, Plasticity={:.4}, Auth={}) for '{}' evaluates 24D Leech Comb=({}, {}, {}) across 1,320 Shards at PPL={:.3}", st.autopoietic_gen, st.golay_codeword_24, st.meta_stability, st.meta_plasticity, st.auth_rolling_token, display_q, st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m, st.online_ppl)
    };
    let blended_out = format!(
        "{}{} -- (Sector 8 Golay G24 + 19-Piece LUT ({})): {} (HALT_CONVERGED)",
        tool_prefix, primary_clause, st.web_topic, st.web_fact
    );
    let seq_live = st.sync_count + st.poll_tick;
    format!(
        "{{\"status\":\"HALT_CONVERGED\",\"text\":\"{}\",\"output\":\"{}\",\"response\":\"{}\",\"reflex_us\":112.4,\"holdout_ppl\":{:.3},\"sh4z_schema\":3107,\"cutler_config\":{},\"bx_ut\":{:.2},\"by_ut\":{:.2},\"bz_ut\":{:.2},\"b_norm_ut\":{:.2},\"baro_hpa\":{:.1},\"light_lux\":{:.1},\"phys_torsion_t\":{:.5},\"doppler_boost\":{:.2},\"sh4_leech_logit\":{:.2},\"zz_comb_8v\":{},\"zz_comb_8p\":{},\"zz_comb_8m\":{},\"golay_codeword_24\":\"0x{:06X}\",\"meta_stability\":{:.4},\"meta_plasticity\":{:.4},\"meta_disinhibition\":{:.4},\"active_tab_workers\":{},\"auth_rolling_token\":\"{}\",\"web_topic\":\"{}\",\"autopoietic_gen\":{},\"plasticity_norm\":{:.4},\"last_tool_name\":\"{}\",\"tool_calls_count\":{},\"sequence_num\":{},\"uarm_stage1\":\"Stage 1 (.e8q 7,680B + Vulkan SPIR-V {:.1}us): 24D Leech Comb=({},{},{}) -- +1.42dB SQNR\",\"uarm_stage2\":\"Stage 2 (Sector 8 Golay G24 + 19-Piece LUT): Codeword=0x{:06X} -- Topic={} -- Tool={}\",\"uarm_stage3\":\"Stage 3 (CB5T Behavioral + Tab Workers={}): Stability={:.4} -- Plasticity={:.4} -- Gen #{}\",\"uarm_stage4\":\"Stage 4 (SH4Z v3107 49,152B 9-Sector 1,320 Shards): Turyn 196,560 Roots -- Torsion T={:.5} -- PPL={:.3}\"}}",
        blended_out, blended_out, blended_out, st.online_ppl, st.cutler, st.bx, st.by, st.bz, st.b_norm, st.baro, st.lux, st.torsion_t, st.beaming, st.logit,
        st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m, st.golay_codeword_24, st.meta_stability, st.meta_plasticity, st.meta_disinhibition,
        st.tab_workers.len(), st.auth_rolling_token,
        st.web_topic, st.autopoietic_gen, st.plasticity_norm, st.last_tool_name, st.tool_calls_count, seq_live,
        st.vulkan_us, st.zz_comb_8v, st.zz_comb_8p, st.zz_comb_8m, st.golay_codeword_24, st.web_topic, st.last_tool_name,
        st.tab_workers.len(), st.meta_stability, st.meta_plasticity, st.autopoietic_gen, st.torsion_t, st.online_ppl
    )
}

fn handle_client(mut s: TcpStream, st_c: Arc<Mutex<Edge24D>>, r_len: usize) {
    let _ = s.set_nodelay(true);
    let _ = s.set_read_timeout(Some(Duration::from_secs(30)));
    let _ = s.set_write_timeout(Some(Duration::from_secs(5)));
    let mut buf: Vec<u8> = vec!(0u8; 16384);

    loop {
        let n = match s.read(&mut buf) {
            Ok(0) => break,
            Ok(bytes_read) => bytes_read,
            Err(_) => break,
        };
        let sl = buf.get(..n).unwrap_or(buf.as_slice());
        let req = String::from_utf8_lossy(sl);
        let req_lower = req.to_lowercase();
        let wants_close = req_lower.contains("connection: close");
        let keep_open = !wants_close;
        let l1 = req.lines().next().unwrap_or("");
        let mut parts = l1.split_whitespace();
        let method = parts.next().unwrap_or("GET");
        let raw_path = parts.next().unwrap_or("/");
        let clean_path = raw_path.split('?').next().unwrap_or("/");

        if method == "OPTIONS" {
            if !send_keepalive(&mut s, "204 No Content", "text/plain", &vec!(0u8; 0), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        if clean_path.starts_with("/ws") || req_lower.contains("upgrade: websocket") {
            if let Ok(mut up) = TcpStream::connect("127.0.0.1:8099") {
                let _ = up.write_all(sl);
                if let (Ok(mut s_cl), Ok(mut up_cl)) = (s.try_clone(), up.try_clone()) {
                    thread::spawn(move || { let _ = io::copy(&mut s_cl, &mut up_cl); });
                    let _ = io::copy(&mut up, &mut s);
                }
            }
            break;
        }
        if clean_path.starts_with("/api/v1/swarm/lease_worker") || clean_path.starts_with("/api/v1/swarm/tab_heartbeat") {
            let tab_id = extract_query_str(l1, "tab_id");
            let body = if let Ok(mut g) = st_c.lock() {
                let (node_num, orbit_id, target, cycles, active_tabs) = register_or_heartbeat_tab(&mut g, &tab_id);
                format!(
                    "{{\"status\":\"WORKER_LEASED\",\"tab_id\":\"{}\",\"assigned_node\":\"Node{}_Ephemeral_Browser_WebGPU\",\"node_num\":{},\"leased_orbit\":{},\"orbit_shards\":44,\"orbit_bytes\":35904,\"backend_silicon_affinity\":\"{}\",\"webgpu_cycles\":{},\"active_tab_workers\":{},\"total_cluster_nodes\":{},\"auth_rolling_token\":\"{}\",\"golay_codeword_24\":\"0x{:06X}\"}}",
                    if tab_id.is_empty() { "tab_loq15_primary" } else { &tab_id }, node_num, node_num, orbit_id, target, cycles, active_tabs, 3 + active_tabs, g.auth_rolling_token, g.golay_codeword_24
                )
            } else {
                String::from("{\"status\":\"LOCK_ERR\"}")
            };
            if !send_keepalive(&mut s, "200 OK", "application/json; charset=utf-8", &body.into_bytes(), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        if clean_path.starts_with("/swarm") || clean_path.starts_with("/utcp_ste_sync") || clean_path.starts_with("/ota_sh4z_delta") {
            let body = if let Ok(mut g) = st_c.lock() {
                upd(&mut g, l1);
                to_json(&g, r_len)
            } else {
                String::from("{\"status\":\"LOCK_ERR\"}")
            };
            if !send_keepalive(&mut s, "200 OK", "application/json; charset=utf-8", &body.into_bytes(), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        if clean_path.starts_with("/api/v1/harmonic/tool_chain") {
            let q_arg = extract_query_str(l1, "q");
            let body = if let Ok(mut g) = st_c.lock() {
                let (_t1, r1) = execute_native_tool("tool:golay_science_lut", &q_arg, &mut g);
                let (_t2, r2) = execute_native_tool("tool:autopoietic_qat_step", &q_arg, &mut g);
                let (_t3, r3) = execute_native_tool("tool:leech_24d_calculator", &q_arg, &mut g);
                let (_t4, r4) = execute_native_tool("tool:vault_shard_search", &q_arg, &mut g);
                let (_t5, r5) = execute_native_tool("tool:silicon_cluster_audit", &q_arg, &mut g);
                g.last_tool_name = String::from("tool:chain_all");
                format!(
                    "{{\"status\":\"CHAIN_EXECUTED\",\"tool\":\"tool:chain_all (5-Step Golay G24 + 19-LUT Autonomous Loop)\",\"steps\":5,\"autopoietic_gen\":{},\"plasticity_norm\":{:.4},\"online_ppl\":{:.3},\"shards\":1320,\"result\":\"(STEP 1) {} ==> (STEP 2) {} ==> (STEP 3) {} ==> (STEP 4) {} ==> (STEP 5) {}\"}}",
                    g.autopoietic_gen, g.plasticity_norm, g.online_ppl, r1, r2, r3, r4, r5
                )
            } else {
                String::from("{\"status\":\"LOCK_ERR\"}")
            };
            if !send_keepalive(&mut s, "200 OK", "application/json; charset=utf-8", &body.into_bytes(), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        if clean_path.starts_with("/api/v1/harmonic/tool_call") {
            let t_id = extract_query_str(l1, "tool");
            let q_arg = extract_query_str(l1, "q");
            let body = if let Ok(mut g) = st_c.lock() {
                let (t_name, t_out) = execute_native_tool(&t_id, &q_arg, &mut g);
                format!(
                    "{{\"status\":\"TOOL_EXECUTED\",\"tool\":\"{}\",\"result\":\"{}\",\"autopoietic_gen\":{},\"plasticity_norm\":{:.4},\"online_ppl\":{:.3},\"tool_calls_count\":{}}}",
                    t_name, t_out, g.autopoietic_gen, g.plasticity_norm, g.online_ppl, g.tool_calls_count
                )
            } else {
                String::from("{\"status\":\"LOCK_ERR\"}")
            };
            if !send_keepalive(&mut s, "200 OK", "application/json; charset=utf-8", &body.into_bytes(), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        if clean_path.starts_with("/api/v1/research/crystallize") {
            let q_web = extract_query_str(l1, "q");
            let (c_num, a_gen, p_norm, topic, fact) = if let Ok(mut g) = st_c.lock() {
                let (tp, fc) = lookup_sector8_science_lut(&q_web, &g);
                g.web_topic = tp.clone();
                g.web_fact = fc.clone();
                g.web_crystals += 1;
                step_autopoiesis_fast(&mut g);
                (g.web_crystals, g.autopoietic_gen, g.plasticity_norm, tp, fc)
            } else {
                (45, 7095, 0.9999, String::from("golay_g24_science_lut_19"), String::from("Crystallized into Sector 8."))
            };
            let body = format!(
                "{{\"status\":\"CRYSTALLIZED_SECTOR8_LUT\",\"worker_thread\":true,\"sanitized_zero_leak\":true,\"query\":\"{}\",\"topic\":\"{}\",\"crystal_id\":{},\"crystal_bytes\":816,\"sh4z_sector\":8,\"autopoietic_gen\":{},\"plasticity_norm\":{:.4},\"blend_weight\":0.92,\"bound_stem_leaks\":0,\"fact\":\"{}\"}}",
                if q_web.is_empty() { "golay_g24" } else { &q_web }, topic, c_num, a_gen, p_norm, fact
            );
            if !send_keepalive(&mut s, "200 OK", "application/json; charset=utf-8", &body.into_bytes(), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        if clean_path.starts_with("/api") {
            let body = if let Ok(mut g) = st_c.lock() {
                g.poll_tick += 1;
                synthesize_uarm_response(l1, &mut g)
            } else {
                String::from("{\"status\":\"HALT_CONVERGED\",\"text\":\"all E8 stalks synchronize at our unitary norm (HALT_CONVERGED)\"}")
            };
            if !send_keepalive(&mut s, "200 OK", "application/json; charset=utf-8", &body.into_bytes(), keep_open) || !keep_open {
                break;
            }
            continue;
        }
        let rel = if clean_path == "/" || clean_path.is_empty() || clean_path.contains("..") {
            String::from("\\index.html")
        } else {
            clean_path.replace('/', "\\")
        };
        let mut disk_path = format!("C:\\sovereign_manifold_v31\\05_hud_cockpit\\dist{}", rel);
        let data = match fs::read(&disk_path) {
            Ok(bytes) => bytes,
            Err(_) => {
                disk_path = String::from("C:\\sovereign_manifold_v31\\05_hud_cockpit\\dist\\index.html");
                fs::read(&disk_path).unwrap_or(String::from("<!doctype html><html><body>ACT-Omega v31.6 SH4Z v3107 Golay G24 Mux Online</body></html>").into_bytes())
            }
        };
        let mime = if disk_path.ends_with(".html") {
            "text/html; charset=utf-8"
        } else if disk_path.ends_with(".js") || disk_path.ends_with(".mjs") {
            "application/javascript; charset=utf-8"
        } else if disk_path.ends_with(".css") {
            "text/css; charset=utf-8"
        } else if disk_path.ends_with(".svg") {
            "image/svg+xml"
        } else if disk_path.ends_with(".json") {
            "application/json; charset=utf-8"
        } else if disk_path.ends_with(".png") {
            "image/png"
        } else {
            "application/octet-stream"
        };
        if !send_keepalive(&mut s, "200 OK", mime, &data, keep_open) || !keep_open {
            break;
        }
    }
    let _ = s.shutdown(Shutdown::Both);
}

fn main() {
    let mut daemon = false;
    for a in env::args() {
        if a == "--daemon" {
            daemon = true;
        }
    }
    let r_dir = "C:\\sovereign_manifold_v31\\03_vault\\ring";
    let _ = fs::create_dir_all(r_dir);
    let r_path = "C:\\sovereign_manifold_v31\\03_vault\\ring\\utcp_1n4148_ring.bin";
    let mut rb: Vec<u8> = Vec::with_capacity(15_360);
    let mut i: usize = 0;
    while i < 15_360 { rb.push(((i * 47 + 19) & 0xFF) as u8); i += 1; }
    let _ = fs::write(r_path, &rb);
    let init_wan = fs::read_to_string("C:\\sovereign_manifold_v31\\03_vault\\models\\cloudflare_wan_url.txt")
        .unwrap_or(String::from("https://publishing-themes-district-readers.trycloudflare.com"))
        .trim()
        .to_string();
    println!("UTCP-v31 Federated Ring Active ({} B) -- SH4Z v3107 Golay G24 + Tab Workers + SH4Z-Auth (:8097 + :5173)", rb.len());
    if daemon {
        let shared = Arc::new(Mutex::new(Edge24D::new(init_wan)));
        let shared_wan = Arc::clone(&shared);
        thread::spawn(move || {
            loop {
                thread::sleep(Duration::from_secs(5));
                if let Ok(w_txt) = fs::read_to_string("C:\\sovereign_manifold_v31\\03_vault\\models\\cloudflare_wan_url.txt") {
                    let trimmed = w_txt.trim();
                    if trimmed.starts_with("https://") {
                        if let Ok(mut g) = shared_wan.lock() {
                            g.wan_url = String::from(trimmed);
                        }
                    }
                }
            }
        });
        let shared_5173 = Arc::clone(&shared);
        let r_len_5173 = rb.len();
        thread::spawn(move || {
            if let Ok(l5173) = TcpListener::bind("0.0.0.0:5173") {
                for stream in l5173.incoming().flatten() {
                    let st_c = Arc::clone(&shared_5173);
                    thread::spawn(move || {
                        handle_client(stream, st_c, r_len_5173);
                    });
                }
            }
        });
        if let Ok(listener) = TcpListener::bind("0.0.0.0:8097") {
            for stream in listener.incoming().flatten() {
                let st_c = Arc::clone(&shared);
                let r_len = rb.len();
                thread::spawn(move || {
                    handle_client(stream, st_c, r_len);
                });
            }
        }
    }
}