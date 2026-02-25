TOP    = max1000_riscv_top
JSON   = $(TOP).json
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

WORK_SRCS = projects/max1000_riscv/sys_pll.vhd \
            projects/max1000_riscv/max1000_riscv_top.vhd

.PHONY: all clean analyze-libs analyze-work

all: $(JSON)

$(WDIR):
	mkdir -p $(WDIR)

analyze-libs: | $(WDIR)
	$(GHDL) -a $(GHDL_FLAGS) --work=types        $(TYPES_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=riscv_common $(RISCV_COMMON_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=rv32i        $(RV32I_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=sdram        $(SDRAM_SRCS)
	$(GHDL) -a $(GHDL_FLAGS) --work=utils        $(UTILS_SRCS)

analyze-work: analyze-libs
	$(GHDL) -a $(GHDL_FLAGS) --work=work $(WORK_SRCS)

$(JSON): analyze-work
	$(YOSYS) -p 'ghdl $(GHDL_FLAGS) $(WORK_SRCS) -e $(TOP); synth_intel_altera -family max10 -json $@'

clean:
	rm -rf $(WDIR) $(JSON)
