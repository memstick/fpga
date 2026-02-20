SYSROOT := $(shell rustc --print sysroot)
HOST := $(shell rustc -vV | sed -n 's/^host: //p')
LLVM_OBJCOPY := $(SYSROOT)/lib/rustlib/$(HOST)/bin/llvm-objcopy
LLVM_OBJDUMP := $(SYSROOT)/lib/rustlib/$(HOST)/bin/llvm-objdump
LLVM_READELF := $(SYSROOT)/lib/rustlib/$(HOST)/bin/llvm-readelf

ifneq (,$(wildcard /opt/riscv/bin/riscv32-unknown-elf-objcopy))
OBJCOPY := /opt/riscv/bin/riscv32-unknown-elf-objcopy
OBJDUMP := /opt/riscv/bin/riscv32-unknown-elf-objdump
READELF := /opt/riscv/bin/riscv32-unknown-elf-readelf
else
OBJCOPY := $(LLVM_OBJCOPY)
OBJDUMP := $(LLVM_OBJDUMP)
READELF := $(LLVM_READELF)
endif

TARGET := riscv32i-unknown-none-elf
ELF := target/$(TARGET)/release/helloworld_rust
BIN := hello.bin

all: romcode objdump readelf

build:
	cargo build --release --target $(TARGET)

$(BIN): build
	$(OBJCOPY) --strip-debug -O binary $(ELF) $(BIN)

romcode: $(BIN)
	./dumpmachinecode.py > $@
	cat $@

objdump: build
	$(OBJDUMP) -D $(ELF) > $@

readelf: build
	$(READELF) -a $(ELF) > $@

clean:
	cargo clean
	rm -f $(BIN) romcode objdump readelf

.PHONY: all build romcode objdump readelf clean
