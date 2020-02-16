[bits 32]

%include "constants.inc"
extern create_virtual_page

start_kernel:
  mov eax, KERNEL_STACK_BASE
  mov esp, eax

  ; Print time at top right corner  
  mov word [VIDEO_BUFFER + 144], 0x0f30
  mov word [VIDEO_BUFFER + 146], 0x0f30
  mov word [VIDEO_BUFFER + 148], 0x0f3a
  mov word [VIDEO_BUFFER + 150], 0x0f30
  mov word [VIDEO_BUFFER + 152], 0x0f30
  mov word [VIDEO_BUFFER + 154], 0x0f3a
  mov word [VIDEO_BUFFER + 156], 0x0f30
  mov word [VIDEO_BUFFER + 158], 0x0f30

  ; create entry in IDT for interrupts 13, 32, 48 
  mov ebx, exGP_handler
  mov edx, int13_gate
  call create_int_gate32

  mov ebx, timer_handler
  mov edx, int32_gate
  call create_int_gate32

  mov ebx, my_handler
  mov edx, int48_gate
  call create_int_gate32

  mov ebx, exPF_handler
  mov edx, int14_gate
  call create_int_gate32

  lidt [idtr]


turn_on_vm:
; KERNEL PAGE
  mov eax, start_kernel
  mov edx, eax
  call create_virtual_page

  mov eax, VIDEO_BUFFER
  mov edx, eax
  call create_virtual_page

; STACK PAGE
  mov eax, KERNEL_STACK_BASE 
  mov edx, eax
  call create_virtual_page

  mov eax, 0x7E00
  mov edx, eax
  call create_virtual_page


	mov eax, PDE_BASE
	mov cr3, eax

  mov eax, cr0	
	or eax, 0x80000000
	mov cr0, eax

interrupts_on:

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
  int 0x30

test:
  nop
  nop
  nop

  ;mov ax, 0x0f30 
  ;mov word [VIDEO_BUFFER], ax
  
  mov edx, kernel_string
  mov ecx, KERNEL_STRLEN
  mov esi, 5
  mov edi, 0
  call print_32  

  jmp $

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

exPF_handler:
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


kernel_string db 'Start kernel', 0
KERNEL_STRLEN equ $ - kernel_string

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

CODE_SELECTOR equ 00001000b
DATA_SELECTOR equ 00010000b

times 1534 - ($ -$$) db 0
dw 0xAACC
