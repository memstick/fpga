MEMORY
{
  ROM (rx) : ORIGIN = 0x40000000, LENGTH = 4K
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 32M
}

SECTIONS
{
  .text : {
    *(.text*)
    *(.rodata*)
  } > ROM

  .data : AT (LOADADDR(.text) + SIZEOF(.text)) {
    *(.data*)
  } > RAM

  .bss (NOLOAD) : {
    *(.bss*)
    *(COMMON)
  } > RAM

  .stack (NOLOAD) : {
    . = ALIGN(16);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
    . = _stack_top;
  } > RAM
}
