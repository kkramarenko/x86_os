[bits 16]
;[org 0x7c00]

start:
	cli 
	lgdt [gdtr]
	mov eax, cr0
	or al, 0x1
	mov cr0, eax
	jmp 0x8:protected_mode

align 8
gdt:
	null_desc times 8 db 0
	code_desc db 0xff, 0xff, 0x0, 0x0, 0x0, 10011010b, 11001111b, 0x0 
	data_desc db 0xff, 0xff, 0x0, 0x0, 0x0, 10010010b, 11001111b, 0x0
  stack_desc db 0x01, 0x0, 0x0, 0x0, 0xff, 10010110b, 11000000b, 0x0
gdt_end:

gdtr:
	dw gdt_end - gdt 
	dd gdt 

;code_selector equ code_desc - gdt

[bits 32]
protected_mode:
;  mov eax, 1
;  cpuid
; create gate int 13
;  mov eax, exGP_handler
;  and eax, 0xFFFF
;  mov [int13_gate], ax
;  mov dword [int13_gate + 2], 0x8
;  mov dword [int13_gate + 4], 1000111000000000b  
;  mov eax, exGP_handler
;  shr eax, 16
;  mov [int13_gate + 6], ax 

  mov ebx, exGP_handler
  mov edx, int13_gate
  call create_int_gate

  mov ebx, timer_handler
  mov edx, int32_gate
  call create_int_gate

	mov ax, 0x4041
	mov [0xb8000], ax

	mov ax, 00010000b
	mov ds, ax
  mov ax, 00011000b
  mov ss, ax
  mov esp, stack_base

  call print

  lidt [idtr]
  
  mov bx, 0x2820
  mov al, 00010001b
  out 0x20, al
  out 0xa0, al
  mov al, bh
  out 0xa1, al
  mov al, 00000100b
  out 0x21, al
  mov al, 2
  out 0xa1, al
  mov al, 00000001b
  out 0x21, al
  out 0xa1, al

  in al, 0x70
  and al, 0x7f
  out 0x70, al

  sti
  
  jmp $

;paging_on:
;	mov eax, paging_on
;	mov ebx, paging_on

;create_pde:
;	shr eax, 22
;	shl eax, 2
;	mov esi, pde_base
;	add esi, eax
	
;	mov eax, pte_base
;	or eax, 011b
;	mov [esi], eax

;create_pte:
; Adding code page in PTE
;	mov esi, pte_base
;	mov eax, paging_on
;	shl eax, 10
;	shr eax, 22
;	shl eax, 2
;	add esi, eax

;	mov eax, ebx
;	shr eax, 12
;	shl eax, 12
;	or eax, 011b
;	mov [esi], eax

; Adding video buffer page in PTE
;	mov esi, pte_base
;	mov eax, video_buffer
;	shl eax, 10
;	shr eax, 22
;	shl eax, 2
;	add esi, eax
	
;	mov eax, video_buffer
;	shr eax, 12
;	shl eax, 12
;	or eax, 011b
;	mov [esi], eax

;turn_on:
;	mov eax, pde_base
;	mov cr3, eax

;	mov eax, cr0	
;	or eax, 0x80000000
;	mov cr0, eax

;	nop
;	nop
;	nop

print:
  pushad
  mov ecx, 4
  xor ebx, ebx
.cycle:
	mov eax, [message + ebx * 2]
	mov [video_buffer + ebx * 2 + 2] , eax
	inc ebx
	loop .cycle
  popad
  ret

; ebx - 32 bits address of gate 
; edx - link in idt for vector
create_int_gate:
  pushad
  mov eax, ebx
  and eax, 0xFFFF
  mov [edx], ax
  mov dword [edx + 2], 0x8
  mov dword [edx + 4], 1000111000000000b  
  mov eax, ebx
  shr eax, 16
  mov [edx + 6], ax 
  popad
  ret 

end:
	jmp $

message:
	db 'H', 0x35, 'e', 0x35, 'l', 0x35, 'l', 0x35, 'o', 0x35	

pde_base equ 4096
	
pte_base equ 8192

test_video equ 0x5000
video_buffer equ 0xb8000

stack_base equ 0xffff 

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
  dq 0; int 14
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
int32_gate:
  dq 0; int 32 - system timer
idt_end:

idtr:
  dw idt_end - idt
  dd idt

exGP_handler:
  pop eax
  iretd

timer_handler:
  push ebx
  push eax
  push edx

  xor edx, edx
  inc dword [counter]
  mov eax, [counter]
  mov ebx, 18
  div ebx
  cmp edx, 0
  jnz .cont
  
  add eax, 0x4000
  mov [0xb8000], ax
 
.cont:
  pop edx
  pop eax
  pop ebx

  push ax
  mov al, 0x20
  out 0x20, al
  out 0xa0, al
  pop ax
  iretd

counter dd 0
;times 510 - ($ - $$) db 0
;dw 0xAA55

