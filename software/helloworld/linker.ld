  MEMORY
  {
    ROM (rx) : ORIGIN = 0x40000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 32M
  }

  SECTIONS
  {
	.initf : AT(0x40000000) {
		KEEP(*(.initf))
	} > ROM

	.text :
	{
		*(.text)
		*(.text.*)
	} > ROM

	.rodata : AT (LOADADDR(.text) + SIZEOF(.text))
	{
		*(.rodata)
		*(.rodata.*)
	} > ROM

	.srodata : AT (LOADADDR(.text) + SIZEOF(.text) + SIZEOF(.rodata))
	{
		*(.srodata)
		*(.srodata.*)
	} > ROM

	.data : AT (LOADADDR(.srodata) + SIZEOF(.srodata))
	{
		*(.data)
		*(.data.*)
	} > RAM

	.sdata : AT (LOADADDR(.data) + SIZEOF(.data))
	{
		*(.sdata)
		*(.sdata.*)
	} > RAM

	.bss (NOLOAD) :
	{
		*(.bss)
		*(.bss.*)
		*(COMMON)
	} > RAM

	.sbss (NOLOAD) :
	{
		*(.sbss)
		*(.sbss.*)
	} > RAM

	.stack (NOLOAD) :
	{
		. = ALIGN(16);
		_stack_top = ORIGIN(RAM) + LENGTH(RAM);
		. = _stack_top;
	} > RAM
  }
