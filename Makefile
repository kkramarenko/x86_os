SRC_FILE := test.asm
OUT_FILE := test.bin
OUT_OBJECT := test.o
DEBUG_FILE := test.dbg
LINK_FILE := test.ld
ASM_COMPILE := nasm
ASM_FLAGS := -f bin
ASM_FLAGS_DBG := -f elf64 -F dwarf -g
LD_EXEC := ld
LD_FLAGS := --oformat binary

.PHONY = all clean debug

all: $(OUT_FILE)

$(OUT_FILE): $(SRC_FILE)
		$(ASM_COMPILE) $(ASM_FLAGS) -o $@ $<
	
debug: 
		$(ASM_COMPILE) $(ASM_FLAGS_DBG) -o $(OUT_OBJECT) $(SRC_FILE)
		$(LD_EXEC) $(LD_FLAGS) -o $(OUT_FILE) -T $(LINK_FILE) $(OUT_OBJECT)
		$(LD_EXEC) -o $(DEBUG_FILE) -T $(LINK_FILE) $(OUT_OBJECT) 

clean:
		rm -rf *.o *.bin *.img *.dbg

