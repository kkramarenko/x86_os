[DEBUG]

To create debug files for gdb and binaries run:
$make debug

After run qemu in first terminal:
$qemu-system-x86_64 test.bin -nographic -curses -s -S

Open next terminal and run:
$gdb test.dbg
gdb> target remote :1234
gdb> break start
gdb> c
gdb> n [or another gdb command]
... 
