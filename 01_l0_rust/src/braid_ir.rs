#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BraidOpcode {
    ParityAssert    = 0x01,
    SheafCheck      = 0x02,
    AfeAnti         = 0x03,
    Stomachion      = 0x04,
    Cross           = 0x05,
    FarCommute      = 0x06,
    HilbertRotate   = 0x07,
    AfeGate         = 0x08,
    SheafCoboundary = 0x09,
    Reserved        = 0x00,
}

impl From<u8> for BraidOpcode {
    fn from(val: u8) -> Self {
        match val {
            0x01 => BraidOpcode::ParityAssert,
            0x02 => BraidOpcode::SheafCheck,
            0x03 => BraidOpcode::AfeAnti,
            0x04 => BraidOpcode::Stomachion,
            0x05 => BraidOpcode::Cross,
            0x06 => BraidOpcode::FarCommute,
            0x07 => BraidOpcode::HilbertRotate,
            0x08 => BraidOpcode::AfeGate,
            0x09 => BraidOpcode::SheafCoboundary,
            _ => BraidOpcode::Reserved,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BraidFlags {
    pub far_commute_parallel: bool,
    pub afe_interlock: bool,
    pub parity_assert_trap: bool,
    pub telemetry_ingest: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BraidInstruction {
    pub opcode: BraidOpcode,
    pub flags: BraidFlags,
    pub rd: u8,
    pub rs1: u8,
    pub rs2: u8,
    pub imm7: i8,
}

impl BraidInstruction {
    #[inline(always)]
    pub fn decode(raw: u32) -> Self {
        let opcode_raw = ((raw >> 26) & 0x3F) as u8;
        let flags_raw = ((raw >> 22) & 0x0F) as u8;
        let rd = ((raw >> 17) & 0x1F) as u8;
        let rs1 = ((raw >> 12) & 0x1F) as u8;
        let rs2 = ((raw >> 7) & 0x1F) as u8;

        let imm_raw = (raw & 0x7F) as u8;
        let imm7 = if (imm_raw & 0x40) != 0 {
            (imm_raw | 0x80) as i8
        } else {
            imm_raw as i8
        };

        let flags = BraidFlags {
            far_commute_parallel: (flags_raw & 0x08) != 0,
            afe_interlock: (flags_raw & 0x04) != 0,
            parity_assert_trap: (flags_raw & 0x02) != 0,
            telemetry_ingest: (flags_raw & 0x01) != 0,
        };

        Self {
            opcode: BraidOpcode::from(opcode_raw),
            flags,
            rd,
            rs1,
            rs2,
            imm7,
        }
    }

    #[inline(always)]
    pub fn can_far_commute_with(&self, other: &BraidInstruction) -> bool {
        if self.opcode != BraidOpcode::Cross || other.opcode != BraidOpcode::Cross {
            return false;
        }
        let diff = (self.rs1 as i32 - other.rs1 as i32).abs();
        diff >= 2
    }
}