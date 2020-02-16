[bits 32]
global ata_read_sectors
global ata_lba_read

; Function for reading cl sectors from disk in LBA/CHS mode
ata_read_sectors:
  push eax
  push ebx
  push ecx
  push edx
  push edi

  mov esi, 1  
.cycle:
  call ata_lba_read
  inc eax
  add edi, 0x200
  loop .cycle  
  
  
  pop edi
  pop edx
  pop ecx
  pop ebx
  pop eax
  ret  

; ATA driver for reading sector in CHS mode
; ebx - chs
; esi  - number of sectors to read
; edi - address where to write data from disk
ata_chs_read:
  push eax
  push ebx
  push ecx
  push edx
  push edi
  push esi
  
  mov edx, 0x1f6     ; port to send drive and head numbers
  mov al, bh         ; head index in bh       
  and al, 00001111b  ; head is only 4 bits long
  or al, 10100000b   ; default high nibble
  out dx, al

  mov edx, 0x1f2     ; sector count port
  mov cx, si
  mov al, cl         ; read cl sectors
  out dx, al   

  mov edx, 0x1f3     ; sector number port
  mov al, bl         ; bl is sector index
  out dx, al
  
  mov edx, 0x1f4     ; cylinder low port
  mov eax, ebx       ; byte 2 in ebx, just above bh
  mov cl, 16
  shr eax, cl
  out dx, al

  mov edx, 0x1f5     ; cylinder high port
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

  mov eax, 512/2    ; number of double word in one secror
  xor bx, bx
  mov cx, si
  mov bl, cl         ; read ch sectors
  mul bx
  mov ecx, eax
  mov edx, 0x1f0     ; data port , in and out
  rep insw           ; in to [edi] 
;.cycle:
;  insw 
; loop .cycle

  pop esi
  pop edi
  pop edx
  pop ecx
  pop ebx
  pop eax

  ret

; ATA driver for reading sector in LBA mode
; eax -lba
; ecx  - number of sectors to read
; edi - address where to write data from disk
ata_lba_read:
  and eax, 0x0FFFFFFF
  push eax
  push ebx
  push ecx
  push edx
  push edi

  mov ebx, eax

  mov edx, 0x1f6
  shr eax, 24
  or al, 11100000b
  out dx, al

  mov edx, 0x1f2
  mov al, cl
  out dx, al

  mov edx, 0x1f3
  mov eax, ebx
  out dx, al

  mov edx, 0x1f4
  mov eax, ebx
  shr eax, 8
  out dx, al
  
  mov edx, 0x1f5
  mov eax, ebx
  shr eax, 16
  out dx, al

  mov edx, 0x1f7
  mov al, 0x20
  out dx, al

.still_going: 
  in al, dx
  test al, 8
  jz .still_going

  mov eax, 256
  xor bx, bx
  mov bl, cl
  mul bx
  mov ecx, eax
  mov edx, 0x1f0
  rep insw

  pop edi
  pop edx
  pop ecx
  pop ebx
  pop eax
  
  ret

