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

#all: $(OUT_FILE)

all: hda.img

$(OUT_FILE): $(SRC_FILE)
		$(ASM_COMPILE) $(ASM_FLAGS) -o $@ $<
	
#debug: 
#		$(ASM_COMPILE) $(ASM_FLAGS_DBG) -o $(OUT_OBJECT) $(SRC_FILE)
#		$(LD_EXEC) $(LD_FLAGS) -o $(OUT_FILE) -T $(LINK_FILE) $(OUT_OBJECT)
#		$(LD_EXEC) -o $(DEBUG_FILE) -T $(LINK_FILE) $(OUT_OBJECT) 

clean:
		rm -rf *.o *.bin *.img *.dbg

#hda.img: boot.o boot.dbg ata_driver.o boot2.o boot2.dbg kernel.o kernel.dbg
# 			nasm -f elf64 -F dwarf -g -o hda.o 	
#	 		ld --oformat binary -o hda.img -M -T hda.ld hda.o 
hda.img: boot.bin boot2.bin kernel.bin
		nasm -f elf64 -F dwarf -g -o hda.o hda.asm
		ld --oformat binary -o hda.img -T hda.ld  hda.o

debug: boot.dbg boot2.dbg kernel.dbg hda.img

boot.bin: boot.o
		ld  --oformat binary -o boot.bin  -T boot.ld  boot.o
	
boot2.bin: boot2.o ata_driver.o
		ld  --oformat binary -o boot2.bin  -T boot2.ld  boot2.o ata_driver.o
	
kernel.bin: kernel.o virtual_memory.o
		ld  --oformat binary -o kernel.bin  -T kernel.ld  kernel.o
	
boot.dbg:  boot.o 
		ld   --oformat binary -o boot.bin  -T boot.ld  boot.o
		ld   -o boot.dbg  -T boot.ld  boot.o

boot2.dbg: boot2.o ata_driver.o
		ld  --oformat binary -o boot2.bin  -T boot2.ld  boot2.o
		ld  -o boot2.dbg  -T boot2.ld  boot2.o ata_driver.o

kernel.dbg: kernel.o virtual_memory.o
		ld  --oformat binary -o kernel.bin -T kernel.ld kernel.o virtual_memory.o
		ld  -o kernel.dbg -T kernel.ld kernel.o virtual_memory.o

boot.o: boot.asm 
		nasm -f elf64 -F dwarf -g -o boot.o boot.asm

boot2.o: boot2.asm 
		nasm -f elf64 -F dwarf -g -o boot2.o boot2.asm

kernel.o: kernel.asm
		nasm -f elf64 -F dwarf -g -o kernel.o kernel.asm

ata_driver.o: ata_driver.asm
		nasm -f elf64 -F dwarf -g -o ata_driver.o ata_driver.asm

virtual_memory.o: virtual_memory.asm
		nasm -f elf64 -F dwarf -g -o virtual_memory.o virtual_memory.asm



