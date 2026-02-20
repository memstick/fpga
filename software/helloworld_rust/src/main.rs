#![no_std]
#![no_main]

use panic_halt as _;
use riscv_rt::entry;

#[entry]
fn main() -> ! {
    // TODO: replace with UART output once MMIO addresses are finalized.
    loop {
        // Busy-loop.
    }
}
