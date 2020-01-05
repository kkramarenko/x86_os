[bits 16]
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
SYMBOL_ATTRIBUTE equ 0x0f
VIDEO_BUFFER equ 0xb8000
ROW_LEN equ 80 * 2
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
  
  ; Print time at top right corner  
  mov word [VIDEO_BUFFER + 144], 0x0f30
  mov word [VIDEO_BUFFER + 146], 0x0f30
  mov word [VIDEO_BUFFER + 148], 0x0f3a
  mov word [VIDEO_BUFFER + 150], 0x0f30
  mov word [VIDEO_BUFFER + 152], 0x0f30
  mov word [VIDEO_BUFFER + 154], 0x0f3a
  mov word [VIDEO_BUFFER + 156], 0x0f30
  mov word [VIDEO_BUFFER + 158], 0x0f30
  
  mov edx, pm_string
  mov ecx, PM_STRLEN
  mov esi, 2
  mov edi, 0
  call print_32
  
  ; create entry in IDT for interrupts 13, 32 
  mov ebx, exGP_handler
  mov edx, int13_gate
  call create_int_gate32

  mov ebx, timer_handler
  mov edx, int32_gate
  call create_int_gate32

  mov ebx, my_handler
  mov edx, int48_gate
  call create_int_gate32

  lidt [idtr]
  
  ; Initialize interrrupt controllers (i8259), connected in cascade mode 
  mov bx, 0x2820 ; 0x20 offset for primary IPC (IRQ0-7), 
                 ; 0x28 offset for slave IPC (IRQ8-15) 
  mov al, 00010001b
  out 0x20, al
  out 0xa0, al
  mov al, bl
  out 0x21, al
  mov al, bh
  out 0xa1, al
  mov al, 00000100b
  out 0x21, al
  mov al, 2
  out 0xa1, al
  mov al, 00000001b
  out 0x21, al
  out 0xa1, al

  ; Anable NMI (Non-maskable interrupts)
  in al, 0x70
  and al, 0x7f
  out 0x70, al

  ; Enable interrupts
  sti

  mov al, '?'
  mov ah, 0x0e
  xor bh, bh
  int 0x30

  xor ebx, ebx
  xor edi, edi
  xor ecx, ecx
  mov ch, KERNEL_SIZE
  mov edi, KERNEL_MEM_OFFSET
  mov ebx, KERNEL_SECTOR_INDEX 
  call ata_chs_read

debug:
  call CODE_SELECTOR:KERNEL_MEM_OFFSET
 
  jmp $

pm_string db 'Switching to protected mode', 0
PM_STRLEN equ $ - pm_string
KERNEL_SIZE equ 1
KERNEL_SECTOR_INDEX equ 5
KERNEL_MEM_OFFSET equ 0x200000

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

align 8
idt:
  dq 0; int 0
  dq 0; int 1
  dq 0; int 2
  dq 0; int 3
  dq 0; int 4 
  dq 0; int 5
  dq 0; int 6
  dq 0; int 7
  dq 0; int 8
  dq 0; int 9
  dq 0; int 10
  dq 0; int 11
  dq 0; int 12
int13_gate:
  dq 0; int 13 - GP
int14_gate:
  dq 0; int 14 - PF
  dq 0; int 15
  dq 0; int 16
  dq 0; int 17
  dq 0; int 18
  dq 0; int 19 
  dq 0; int 20
  dq 0; int 21
  dq 0; int 22
  dq 0; int 23
  dq 0; int 24
  dq 0; int 25
  dq 0; int 26
  dq 0; int 27
  dq 0; int 28
  dq 0; int 29
  dq 0; int 30
  dq 0; int 31
int32_gate: ; IRQ0-7
  dq 0; int 32 - system timer IRQ0
  dq 0; int 33
  dq 0; int 34
  dq 0; int 35
  dq 0; int 36
  dq 0; int 37
  dq 0; int 38
  dq 0; int 39 - IRQ7
  dq 0; int 40 - IRQ8
  dq 0; int 41
  dq 0; int 42
  dq 0; int 43
  dq 0; int 44
  dq 0; int 45
  dq 0; int 46
  dq 0; int 47 - IRQ15
int48_gate:
  dq 0; int 48 - my handler
idt_end:

idtr:
  dw idt_end - idt
  dd idt

; ebx - 32 bits address of gate 
; edx - link in idt for vector
create_int_gate32:
  pushad
  mov eax, ebx
  and eax, 0xFFFF
  mov [edx], ax
  mov word [edx + 2], CODE_SELECTOR
  mov word [edx + 4], 1000111000000000b  
  mov eax, ebx
  shr eax, 16
  mov word [edx + 6], ax 
  popad
  ret 

exGP_handler:
  pop eax
  iretd

my_handler:
  push ax
  pop ax
  iretd

timer_handler:
  push ebx
  push eax
  push edx

  xor edx, edx
  xor eax, eax
  xor ebx, ebx
  inc byte [counter]
  mov al, [counter]
  mov ebx, 18
  div ebx
  cmp edx, 0
  jnz cont

print_seconds:
  xor eax, eax
  mov [counter], al
  inc byte [seconds]
  mov al, [seconds]
  xor edx, edx
  xor ebx, ebx
  mov ebx, 10
  div ebx

  add eax, 0x0f30
  mov [VIDEO_BUFFER + 156], ax
 
  add edx, 0x0f30
  mov [VIDEO_BUFFER + 158], dx
  
  xor eax, eax
  mov al, [seconds]
  cmp eax, 59
  jne cont

print_minutes:
  xor eax, eax
  mov [seconds], al
  inc byte [minutes]
  mov al, [minutes]
  xor edx, edx
  xor ebx, ebx
  mov ebx, 10
  div ebx

  add eax, 0x0f30
  mov [VIDEO_BUFFER + 150], ax
  
  add edx, 0x0f30
  mov [VIDEO_BUFFER + 152], dx

  xor eax, eax
  mov al, [minutes]
  cmp eax, 59
  jne cont 

print_hours: 
  xor eax, eax
  mov [minutes], al
  inc byte [hours]
  mov al, [hours]
  xor edx, edx
  mov ebx, 10
  div ebx

  add eax, 0x0f30
  mov [VIDEO_BUFFER + 144], ax
  
  add edx, 0x0f30
  mov [VIDEO_BUFFER + 146], dx

  xor eax, eax
  mov al, [hours]
  cmp eax, 23
  jne cont
  xor eax, eax
  mov [hours], al

cont:
  pop edx
  pop eax
  pop ebx
  
  ; 
  push ax
  mov al, 0x20
  out 0x20, al
  out 0xa0, al
  pop ax
  iretd

counter db 0
seconds db 0
minutes db 0
hours db 0

; ATA driver for reading sector in CHS mode
; ebx - chs
; ch  - number of sectors to read
; edi - address where to write data from disk
ata_chs_read:
  push eax
  push ebx
  push ecx
  push edx
  push edi
  
  mov edx, 0x1f6     ; port to send drive and head numbers
  mov al, bh         ; head index in bh       
  and al, 00001111b  ; head is only 4 bits long
  or al, 10100000b   ; default high nibble
  out dx, al

  mov edx, 0x1f2     ; sector count port
  mov al, ch         ; read ch sectors
  out dx, al   

  mov edx, 0x1f3     ; sector number port
  mov al, bl         ; bl is sector index
  out dx, al
  
  mov edx, 0x1f4     ; cylinder low port
  mov eax, ebx       ; byte 2 in ebx, just above bh
  mov cl, 16
  shr eax, cl
  out dx, al

  mov edx, 0x1f5     ; cylinder low port
  mov eax, ebx       ; byte 2 in ebx, just above bh
  mov cl, 24
  shr eax, cl
  out dx, al

  mov edx, 0x1f7     ; command port
  mov al, 0x20       ; read with retry
  out dx, al

.still_going: 
  in al, dx
  test al, 8         ; the sector buffer requires servicing
  jz .still_going    ; until the sector buffer is ready
 
  mov eax, 512/2     ; number of word in one secror
  xor bx, bx
  mov bl, ch         ; read ch sectors
  mul bx
  mov ecx, eax
  mov edx, 0x1f0     ; data port , in and out
  rep insw           ; in to [edi] 

  pop edi
  pop edx
  pop ecx
  pop ebx
  pop eax

  ret

times  1536 - ($ - $$) db 0
