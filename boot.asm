[bits 16]
; BIOS load boot device code in DL register
first_stage:
  mov ax, cs
  mov ds, ax
  mov ss, ax
  mov sp, [stack_top]

; Save boot device 
  mov [boot_device], dl  
  call clear_screen

  xor eax, eax
  mov dx, hello_string
  mov cx, HELLO_STRLEN
  call print 

  call read_disk

jump_to_second_stage:
  jmp 0x0:SECOND_STAGE_BASE

  jmp $

print:
  pushad
  xor ebx, ebx
  mov bx, 0
.cycle:
  mov ah, SYMBOL_ATTRIBUTE
  mov al, [edx + ebx]
  mov [VIDEO_BUFFER + ebx * 2], eax
  inc bx
  loop .cycle
  popad
  ret

clear_screen:
  pushad
  xor cx, cx
  xor bx, bx
  mov cx, SCREEN_SIZE
  mov al, SPACE
  mov ah, SYMBOL_ATTRIBUTE
.cycle:
  mov [VIDEO_BUFFER + ebx * 2], eax
  inc bx
  loop .cycle
  popad
  ret

read_disk:
  pushad
.retry:
  mov bx, SECOND_STAGE_BASE; address where to copy   
  xor ax, ax    ;
  mov es, ax    ;

  mov ah, 0x2 ; read function
  mov al, 0x3 ; sectors
  mov ch, 0x0 ; cylinder
  mov cl, 0x2 ; sector 
  mov dh, 0x0 ; head
  mov dl, [boot_device] ; drive
  int 0x13
  ;jc .retry 
  popad
  ret
  

hello_string db 'First stage bootloader', 0
HELLO_STRLEN equ $ - hello_string
boot_device db 0
SPACE equ ' '
SYMBOL_ATTRIBUTE equ 0x0f
stack_top dw 0x7bff
VIDEO_BUFFER equ 0xb8000
SCREEN_SIZE equ 80 * 25
SECOND_STAGE_BASE equ 0x500

times 510 - ($ - $$) db 0
dw 0xAA55
start2:
  incbin "boot2.bin"
  incbin "kernel.bin"

