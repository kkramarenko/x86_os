SECTIONS
{
	. = 0x7e00;
	.text :
	{
		__start = .;
		boot2.o(.text)
    ata_driver.o(.text)
    . = 0x5FE;
    SHORT(0x0000)
	}
}
