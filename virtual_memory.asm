[bits 32]
%include "constants.inc"

global create_virtual_page

; Function create PDE and PTE entries for given address
; eax - 32 bits address 
; edx - physical page address

create_virtual_page:
  pushf
  push eax
  push ebx
  push edx
  push esi
  push edi

  mov ebx, eax
create_pde:
	shr eax, 22
	shl eax, 2
	mov esi, PDE_BASE
	add esi, eax
  shr eax, 2

  mov edi, eax
  shl edi, 12 
  
	
	mov eax, PTE_BASE
  add eax, edi
	or eax, 011b
	mov [esi], eax
  and eax, 0xFFFFF000

create_pte:
  mov esi, eax
  mov eax, ebx
  shl eax, 10
  shr eax, 22
  shl eax, 2
  add esi, eax
  
  mov eax, edx
  or eax, 011b
  mov [esi], eax

  pop edi
  pop esi
  pop edx
  pop ebx
  pop eax
  popf

  ret

times (510 - ($ - $$)) db 0
dw 0xAABB 
