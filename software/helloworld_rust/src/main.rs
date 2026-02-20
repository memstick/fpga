#![no_std]
#![no_main]

use core::arch::asm;
use panic_halt as _;

const UART_BASE: usize = 0x2000_0000;
const UART_CTRL: *const u32 = (UART_BASE + 0x0) as *const u32;
const UART_DATA_WR: *mut u32 = (UART_BASE + 0x8) as *mut u32;

fn uart_putc(c: u8) {
    unsafe {
        while core::ptr::read_volatile(UART_CTRL) & 0x1 != 0 {}
        core::ptr::write_volatile(UART_DATA_WR, c as u32);
    }
}

fn uart_puts(s: &str) {
    for &b in s.as_bytes() {
        uart_putc(b);
    }
}

#[no_mangle]
pub extern "C" fn _start() -> ! {
    unsafe {
        asm!("la sp, _stack_top");
    }
    uart_puts("UART hello from Rust!\r\n");
    loop {}
}
