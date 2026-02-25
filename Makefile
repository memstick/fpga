TOP      = max1000_riscv_top
SRCS     = projects/max1000_riscv/max1000_riscv_top.vhd
JSON     = $(TOP).json
YOSYS    = yosys -m ghdl
GHDL     = ghdl
STD      = --std=08
WDIR     = work
GHDL_FLAGS = $(STD) --workdir=$(WDIR) -P$(WDIR) --ieee=synopsys

#LIBS = riscv_common rv32i sdram utils types
LIBS = types riscv_common rv32i sdram utils

# Find all .vhd/.vhdl files in each lib directory
lib_srcs = $(wildcard lib/$(1)/*.vhd) $(wildcard lib/$(1)/*.vhdl)

.PHONY: all clean

all: $(JSON)

$(WDIR):
	mkdir -p $(WDIR)

# Analyze each library
.PHONY: analyze-libs
analyze-libs: | $(WDIR)
	$(foreach lib,$(LIBS), \
		$(GHDL) -a $(GHDL_FLAGS) --work=$(lib) $(call lib_srcs,$(lib));)

$(JSON): analyze-libs
	$(YOSYS) -p 'ghdl $(GHDL_FLAGS) $(SRCS) -e $(TOP); synth_intel_altera -family max10 -json $@'

clean:
	rm -rf $(WDIR) $(JSON)
