[bits 32]
start_kernel:
  nop
  nop
  nop
  nop
  xor eax, eax
  jmp $

times 512 - ($ -$$) db 0
