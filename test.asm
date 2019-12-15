[bits 16]
[org 0x7c00]

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
gdt_end:

gdtr:
	dw gdt_end - gdt 
	dd gdt 


[bits 32]
;align 4
protected_mode:
	mov ax, 0x4041
	mov [0xb8000], ax

	mov ax, 00010000b
	mov ds, ax


paging_on:
	mov eax, paging_on
	mov ebx, paging_on

create_pde:
	shr eax, 22
	shl eax, 2
	mov esi, pde_base
	add esi, eax
	
	mov eax, pte_base
	or eax, 011b
	mov [esi], eax

create_pte:
; Adding code page in PTE
	mov esi, pte_base
	mov eax, paging_on
	shl eax, 10
	shr eax, 22
	shl eax, 2
	add esi, eax

	mov eax, ebx
	shr eax, 12
	shl eax, 12
	or eax, 011b
	mov [esi], eax

; Adding video buffer page in PTE
	mov esi, pte_base
	mov eax, video_buffer
	shl eax, 10
	shr eax, 22
	shl eax, 2
	add esi, eax
	
	mov eax, video_buffer
	shr eax, 12
	shl eax, 12
	or eax, 011b
	mov [esi], eax

turn_on:
	mov eax, pde_base
	mov cr3, eax

	mov eax, cr0	
	or eax, 0x80000000
	mov cr0, eax

	nop
	nop
	nop

	mov ecx, 10
	xor ebx, ebx

print2:
	mov eax, [message + ebx * 2]
	mov [video_buffer + ebx * 2 + 2] , eax
	inc ebx
	loop print2


end:
	jmp $

message:
	db 'H', 0x35, 'e', 0x35, 'l', 0x35, 'l', 0x35, 'o', 0x35	

pde_base equ 4096
	
pte_base equ 8192

test_video equ 0x5000
video_buffer equ 0xb8000

times 510 - ($ - $$) db 0
dw 0xAA55

