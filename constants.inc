; Constants related with text mode 
SYMBOL_ATTRIBUTE equ 0x0f
VIDEO_BUFFER equ 0xb8000
ROW_LEN equ 80 * 2
SCREEN_SIZE equ 80 * 25

; Constants related with kernel attributes
KERNEL_SIZE equ 4
KERNEL_BLOCK_INDEX equ 4
KERNEL_SECTOR_INDEX equ 5
KERNEL_MEM_OFFSET equ 0x200000
KERNEL_STACK_BASE equ 0x3FFFFF

; Virtual memory attributes
PDE_BASE equ 0x1A00000
PTE_BASE equ 0x1200000

