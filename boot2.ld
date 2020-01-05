SECTIONS
{
	. = 0x500;
	.text :
	{
		__start = .;
		*(.text)
	}
}
