ENTRY(_bootloader)

PROVIDE(__BOOT_SECTOR_START  = 0x7C00);

SECTIONS
{
	. = __BOOT_SECTOR_START;
	.init.boot :
	{
		*(.bootloader)
		*(.bootmagic)
	}
	.text : {}

	/DISCARD/:
	{ 
		*(*)
	}
}