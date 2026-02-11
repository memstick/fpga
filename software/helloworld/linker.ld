  MEMORY
  {
    ROM (rx) : ORIGIN = 0x40000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 16K
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
  }
