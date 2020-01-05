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

boot.bin:  boot2.bin kernel.bin boot.o 
		ld --oformat binary -o boot.bin  -T boot.ld  boot.o
		ld  -o boot.dbg  -T boot.ld  boot.o

boot2.bin: boot2.o 
		ld --oformat binary -o boot2.bin  -T boot2.ld  boot2.o
		ld  -o boot2.dbg  -T boot2.ld  boot2.o

kernel.bin: kernel.o
		ld --oformat binary -o kernel.bin -T kernel.ld kernel.o
		ld -o kernel.dbg -T kernel.ld kernel.o

boot.o: boot.asm boot2.o kernel.o
		nasm -f elf64 -F dwarf -g -o boot.o boot.asm

boot2.o: boot2.asm
		nasm -f elf64 -F dwarf -g -o boot2.o boot2.asm

kernel.o: kernel.asm
		nasm -f elf64 -F dwarf -g -o kernel.o kernel.asm

