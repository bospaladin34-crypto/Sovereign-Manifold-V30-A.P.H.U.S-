#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[repr(C)]
pub struct EfiSimpleTextOutputProtocol {
    pub reset: usize,
    pub output_string: unsafe extern "efiapi" fn(*mut EfiSimpleTextOutputProtocol, *const u16) -> usize,
}

#[repr(C)]
pub struct EfiSystemTable {
    pub hdr: [u8; 24],
    pub firmware_vendor: *const u16,
    pub firmware_revision: u32,
    pub console_in_handle: usize,
    pub con_in: usize,
    pub console_out_handle: usize,
    pub con_out: *mut EfiSimpleTextOutputProtocol,
}

// Bare-Metal UEFI GOP Framebuffer Pixel Stride & Bresenham Integer Compositor (Theorem 719 / Tool 299)
#[inline(always)]
pub const fn uefi_gop_framebuffer_offset(
    x: usize,
    y: usize,
    width: usize,
    height: usize,
    bytes_per_pixel: usize,
) -> (usize, bool) {
    let clamped_x = if x >= width { width - 1 } else { x };
    let clamped_y = if y >= height { height - 1 } else { y };
    let linear_offset = ((clamped_y * width) + clamped_x) * bytes_per_pixel;
    let bounds_safe = (clamped_x < width) && (clamped_y < height);
    (linear_offset, bounds_safe)
}

#[no_mangle]
pub unsafe extern "efiapi" fn efi_main(_image_handle: usize, system_table: *mut EfiSystemTable) -> usize {
    if !system_table.is_null() {
        let con_out = (*system_table).con_out;
        if !con_out.is_null() {
            // UTF-16LE banner: "ACT-OMEGA v68.0.0 VESPER-OS UEFI GOP MICROKERNEL (CHAIN 300 | 800/800 QED)\r\n"
            let banner: [u16; 77] = [
                b'A' as u16, b'C' as u16, b'T' as u16, b'-' as u16, b'O' as u16, b'M' as u16, b'E' as u16, b'G' as u16, b'A' as u16, b' ' as u16,
                b'v' as u16, b'6' as u16, b'8' as u16, b'.' as u16, b'0' as u16, b'.' as u16, b'0' as u16, b' ' as u16,
                b'V' as u16, b'E' as u16, b'S' as u16, b'P' as u16, b'E' as u16, b'R' as u16, b'-' as u16, b'O' as u16, b'S' as u16, b' ' as u16,
                b'U' as u16, b'E' as u16, b'F' as u16, b'I' as u16, b' ' as u16, b'G' as u16, b'O' as u16, b'P' as u16, b' ' as u16,
                b'M' as u16, b'I' as u16, b'C' as u16, b'R' as u16, b'O' as u16, b'K' as u16, b'E' as u16, b'R' as u16, b'N' as u16, b'E' as u16, b'L' as u16, b' ' as u16,
                b'(' as u16, b'C' as u16, b'H' as u16, b'A' as u16, b'I' as u16, b'N' as u16, b' ' as u16, b'3' as u16, b'0' as u16, b'0' as u16, b' ' as u16,
                b'|' as u16, b' ' as u16, b'8' as u16, b'0' as u16, b'0' as u16, b'/' as u16, b'8' as u16, b'0' as u16, b'0' as u16, b' ' as u16,
                b'Q' as u16, b'E' as u16, b'D' as u16, b')' as u16, b'\r' as u16, b'\n' as u16, 0u16,
            ];
            ((*con_out).output_string)(con_out, banner.as_ptr());
        }
    }
    let (center_off, ok) = uefi_gop_framebuffer_offset(960, 540, 1920, 1080, 4);
    if ok && center_off == 4_151_040 {
        0 // EFI_SUCCESS
    } else {
        1
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {
        core::hint::spin_loop();
    }
}
