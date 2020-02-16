[bits 16]
%include "constants.inc"

extern ata_read_sectors
extern ata_lba_read

second_stage:
  mov sp, STACK_TOP

  mov dx, hello2_string ; string address
  mov cx, HELLO2_STRLEN ; string len
  mov si, 1 ; row number
  mov di, 0 ; column number
  call print
  
  ; Disable interrupts
  cli

  ; Load GDTR 
  lgdt [gdtr]
  mov eax, cr0
  or al, 0x1
  mov cr0, eax

  jmp CODE_SELECTOR:protected_mode 

  jmp $

print:
  pushad
  push dx
  push di
  mov ax, si
  mov di, ROW_LEN
  mul di
  mov si, ax
  pop di
  mov ax, 2
  mul di
  add si, ax
  pop dx
  xor ebx, ebx
.cycle:
  mov ah, SYMBOL_ATTRIBUTE
  mov al, [edx + ebx]
  mov [VIDEO_BUFFER + esi + ebx * 2], eax
  inc bx
  loop .cycle
  popad
  ret

hello2_string db 'Second stage bootloader', 0
HELLO2_STRLEN equ $ - hello2_string 
STACK_TOP equ 0xffff

align 8
gdt:
	null_desc times 8 db 0
	code_desc db 0xff, 0xff, 0x0, 0x0, 0x0, 10011010b, 11001111b, 0x0 
	data_desc db 0xff, 0xff, 0x0, 0x0, 0x0, 10010010b, 11001111b, 0x0
gdt_end:

gdtr:
	dw gdt_end - gdt 
	dd gdt 

CODE_SELECTOR equ 00001000b
DATA_SELECTOR equ 00010000b

[bits 32]
protected_mode:
  mov ax, DATA_SELECTOR
  mov ds, ax
  mov ss, ax
  mov es, ax
  mov gs, ax
  mov fs, ax
  
  mov edx, pm_string
  mov ecx, PM_STRLEN
  mov esi, 2
  mov edi, 0
  call print_32
  
debug:

  ;xor eax, eax
  ;xor edi, edi
  ;xor ecx, ecx
  ;mov eax, KERNEL_SECTOR_INDEX - 1
  ;mov ecx, KERNEL_SIZE
  ;mov edi, KERNEL_MEM_OFFSET
  ;call ata_lba_read

read_kernel:
  xor ebx, ebx
  xor edi, edi
  xor ecx, ecx
  mov cl, KERNEL_SIZE
  mov edi, KERNEL_MEM_OFFSET
  mov eax, KERNEL_BLOCK_INDEX 
  call ata_read_sectors
  ;mov eax, KERNEL_MEM_OFFSET
  ;add eax, 0x5FE
  ;mov word ebx, [eax]
  ;cmp ebx, 0xAACC
  ;jne read_kernel

  ;mov eax, 0x8400
  ;mov ecx, 0x400
  ;mov ebx, KERNEL_MEM_OFFSET
  ;xor esi, esi
  ;.copy:
  ;mov edx, [eax + esi * 2]
  ;mov [ebx + esi * 2], edx
  ;inc esi
  ;loop .copy

  
 ; xor ebx, ebx
 ; xor edi, edi
 ; xor ecx, ecx
 ; mov ch, 1
 ; mov edi, KERNEL_MEM_OFFSET + 0x200
 ; mov ebx, KERNEL_SECTOR_INDEX + 1
 ; call ata_chs_read
  
  mov edx, kernel_string
  mov ecx, KERNEL_STRLEN
  mov esi, 3
  mov edi, 0
  call print_32  
  
  ;mov ecx, 3
  ;call timer_32 

  ;mov edx, timer_string
  ;mov ecx, TIMER_STRLEN
  ;mov esi, 4
  ;mov edi, 0
  ;call print_32  
 
  jmp CODE_SELECTOR:KERNEL_MEM_OFFSET
 
  jmp $

pm_string db 'Switching to protected mode', 0
PM_STRLEN equ $ - pm_string
kernel_string db 'Kernel loaded to address: 0x200000', 0
KERNEL_STRLEN equ $ - kernel_string
timer_string db 'Time exceed!', 0
TIMER_STRLEN equ $ - timer_string

; Function for string printing at given position (80x25 mode)
; dx - address of string
; cx - length of string
; di - column number 
; si - row number 

print_32:
  pushad
  push edx
  push edi
  mov eax, esi
  mov edi, ROW_LEN
  mul edi
  mov esi, eax
  pop edi
  mov eax, 2
  mul edi
  add esi, eax
  pop edx
  xor ebx, ebx
  xor eax, eax
.cycle:
  mov ah, SYMBOL_ATTRIBUTE
  mov al, [edx + ebx]
  mov [VIDEO_BUFFER + esi + ebx * 2], ax
  inc ebx
  loop .cycle
  popad
  ret

; Function impliments timer wtih help of CMOS time
; cx - seconds number
sec db 0
 
timer_32:
  xor ebx, ebx
  mov al, 0x0
  out 0x70, al
  nop
  nop
  nop
  in al, 0x71
  mov [sec], al

.cycle:
  mov al, 0x0
  out 0x70, al
  nop
  nop
  nop
  in al, 0x71
  cmp al, [sec]
  je .cycle
  mov [sec], al
  inc bx
  cmp bx, cx
  jne .cycle
  ret

;times 1536 - ($ - $$) db 0
