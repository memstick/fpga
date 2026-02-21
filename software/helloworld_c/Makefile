
OBJDUMP=/opt/riscv/bin/riscv32-unknown-elf-objdump
CC=/opt/riscv/bin/riscv32-unknown-elf-gcc
OBJCOPY=/opt/riscv/bin/riscv32-unknown-elf-objcopy
RELFCOPY=/opt/riscv/bin/riscv32-unknown-elf-readelf
STRIP=/opt/riscv/bin/riscv32-unknown-elf-strip

all: rom.mif hello.bin objdump readelf

hello: main.c entry.s
	$(CC) -T linker.ld -march=rv32i -mabi=ilp32 -Os -fomit-frame-pointer -nostdlib $^ -o $@

objdump: hello
	$(OBJDUMP) -D $< > $@

readelf: hello
	$(RELFCOPY) -a $< > $@

hello.bin: hello
	$(STRIP) --strip-debug $<
	$(OBJCOPY) -O binary $< $@

rom.mif: hello.bin
	./dumpmachinecode.py > ../../projects/max1000_riscv/rom.mif
	cat ../../projects/max1000_riscv/rom.mif

clean:
	rm -f objdump hello.* rom.mif

.PHONY: clean all rom.mif
