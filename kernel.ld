SECTIONS
{
	. = 0x200000;
	.text :
	{
		__start = .;
		*(.text)
	}
}
