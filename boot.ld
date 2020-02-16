SECTIONS
{
	. = 0x7c00;
	.text :
	{
		__start = .;
		*(.text)
	}  
}
