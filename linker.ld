ENTRY(kernel_entry)
OUTPUT_ARCH(i386)

SECTIONS {
	. = 0x8200;

	.text :
	{
		*(.text*)
	}

	.rodata :
	{
		*(.rodata*)
	}

	.data :
	{
		*(.data*)
	}

	.bss :
	{
		*(COMMON)
		*(.bss*)
	}
}