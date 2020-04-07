ENTRY(_bootloader)

PROVIDE(__BOOT_SECTOR_START     = 0x7C00);
PROVIDE(__BOOT_SECTOR_FORCE_END = 0x7E00);

SECTIONS
{
	. = __BOOT_SECTOR_START;
	.init.boot :
	{
		*(.bootloader)
		*(.bootmagic)
	}
	. = __BOOT_SECTOR_FORCE_END;
	.text : {}

	/DISCARD/:
	{ 
		*(*)
	}
}