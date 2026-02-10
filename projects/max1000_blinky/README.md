# MAX1000 blinky (VHDL)

Minimal Quartus project for the MAX1000 16K (10M16SAU169C8G).

## What it does
- A 1 Hz tick increments an 8-bit counter.
- The counter drives LED0..LED7 (binary count).

## Clocking
- Board clock input: 12 MHz on pin H6.
- The project instantiates a PLL (`pll15m`) intended to generate a 15 MHz system clock.
  - The current `pll15m.vhd` is a pass-through placeholder so the project compiles.
  - Replace it with a real Quartus PLL IP to get an actual 15 MHz clock.
  - `locked` is synchronized into the 15 MHz domain and used as an enable for the LED counter.

## Generate the PLL in Quartus (12 MHz -> 15 MHz)
1. Open `max1000_blinky.qpf`.
2. Tools → IP Catalog.
3. Search for “PLL” and select **ALTPLL** (or “PLL Intel FPGA IP”).
4. Set input clock to **12 MHz**, output clock `c0` to **15 MHz**.
5. Name the IP `pll15m` and generate in `projects/max1000_blinky/ip/pll15m/`.
6. In Quartus, add the generated `.qip` to the project (Project → Add/Remove Files).
7. Remove or rename the placeholder `pll15m.vhd` to avoid duplicate entities.

After that, recompile; the timing constraints in `max1000_blinky.sdc` already set the 12 MHz input clock and use `derive_pll_clocks`.

## Files
- `max1000_blinky_top.vhd` : top-level (instantiates PLL + LED counter)
- `led_counter.vhd` : 1 Hz counter driving LEDs
- `pll15m.vhd` : PLL placeholder (replace with Quartus PLL IP)
- `max1000_blinky.qpf` : Quartus project file
- `max1000_blinky.qsf` : assignments and constraints
- `max1000_blinky.sdc` : clock constraint

## Build (Quartus)
1. Open `max1000_blinky.qpf`.
2. (Recommended) Generate the PLL IP (steps above).
3. Compile and program the device.
