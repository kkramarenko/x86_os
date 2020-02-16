SECTIONS
{
	. = 0x200000;
	.text :
	{
		__start = .;
		kernel.o(.text)
    virtual_memory.o(.text)
	}
}
