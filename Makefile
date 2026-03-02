# Which FPGA chip to target:

FPGA = ice40

ifeq ($(FPGA),max1000)
    TARGET= synth_intel_altera -family max10
    RV_PCF = projects/max1000_riscv/max1000_riscv-max1000.pcf
    BLINKY_PCF = projects/max1000_blinky/blinky-max1000.pcf
endif
ifeq ($(FPGA),ice40)
    TARGET= synth_ice40
    RV_PCF = projects/max1000_riscv/max1000_riscv-ice40.pcf
    BLINKY_PCF = projects/max1000_blinky/blinky-ice40.pcf
endif

RV_TOP    = max1000_riscv_top
RV_JSON   = $(RV_TOP).json

BLINKY_TOP   = max1000_blinky
BLINKY_JSON   = max1000_blinky.json

YOSYS  = yosys -m ghdl
GHDL   = ghdl
STD    = --std=08
WDIR   = work
GHDL_FLAGS = $(STD) --workdir=$(WDIR) -P$(WDIR) --ieee=synopsys

RISCV_COMMON_SRCS = lib/riscv_common/rv32i_global.vhd

RV32I_SRCS = lib/rv32i/rom_debug.vhd \
             lib/rv32i/rv32i_pkg.vhd \
             lib/rv32i/rv32i.vhd

SDRAM_SRCS = lib/sdram/sdram_ctrl.vhd

TYPES_SRCS = lib/types/types.vhd

UTILS_SRCS = lib/utils/cdc_sync.vhd \
             lib/utils/const0.vhd \
             lib/utils/const1.vhd \
             lib/utils/cpu.vhd \
             lib/utils/crossbar.vhd \
             lib/utils/divider.vhd \
             lib/utils/pll.vhd \
             lib/utils/resettest.vhd \
             lib/utils/reset.vhd \
             lib/utils/rom.vhd \
             lib/utils/spi_lcd.vhd \
             lib/utils/uart_cpu.vhd \
             lib/utils/uart_rx_iso.vhd \
             lib/utils/uart_rx.vhd \
             lib/utils/uart_tx_iso.vhd \
             lib/utils/uart_tx.vhd

RV_WORK_SRCS = \
            projects/max1000_riscv/sys_pll.vhd \
            projects/max1000_riscv/max1000_riscv_top.vhd

BLINKY_WORK_SRCS = \
            projects/max1000_blinky/max1000_blinky.vhd

BLINKY_UNUSED_SRCS = \
	    projects/max1000_blinky/led_counter.vhd \
            projects/max1000_blinky/max1000_blinky_top.vhd \
            projects/max1000_blinky/pll15m.vhd

.PHONY: all clean analyze-libs analyze-work

all: blinky.bin riscv.bin

$(WDIR):
	mkdir -p $(WDIR)

analyze-libs: | $(WDIR)
	$(GHDL) -a $(GHDL_FLAGS) --work=types        $(TYPES_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=riscv_common $(RISCV_COMMON_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=rv32i        $(RV32I_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=sdram        $(SDRAM_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=utils        $(UTILS_SRCS)

analyze-work: analyze-libs
	$(GHDL) -a $(GHDL_FLAGS) --work=work $(RV_WORK_SRCS)

$(RV_JSON): analyze-work
	$(YOSYS) -p "ghdl --latches $(GHDL_FLAGS) $(RV_WORK_SRCS) -e $(RV_TOP); $(TARGET) -json $@"

riscv.bin: $(RV_JSON) $(RV_PCF)
	nextpnr-ice40 --freq 64 --hx8k --package tq144:4k --json $(RV_JSON) --pcf ${RV_PCF} \
	  --asc $@.asc --opt-timing --placer heap
	icebox_explain $@.asc > $@.ex
	icepack $@.asc $@

load_riscv: riscv.bin
	iceprog riscv.bin

$(BLINKY_JSON): | $(WDIR)
	$(YOSYS) -p "ghdl $(GHDL_FLAGS) $(BLINKY_WORK_SRCS) -e $(BLINKY_TOP); $(TARGET) -json $@"

blinky.bin: $(BLINKY_JSON) $(BLINKY_PCF)
	nextpnr-ice40 --freq 64 --hx8k --package tq144:4k --json $(BLINKY_JSON) --pcf ${BLINKY_PCF} \
	  --asc $@.asc --opt-timing --placer heap
	icebox_explain $@.asc > $@.ex
	icepack $@.asc $@

load_blinky: blinky.bin
	iceprog blinky.bin

clean:
	$(RM) -r $(WDIR)
	$(RM) $(BLINKY_JSON) blinky.bin blinky.bin.asc blinky.bin.ex
	$(RM) $(RV_JSON) riscv.bin riscv.bin.asc riscv.bin.ex
