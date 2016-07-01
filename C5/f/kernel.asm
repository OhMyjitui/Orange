



SELECTOR_KERNEL_CS equ 8

extern cstart

extern gdt_ptr

[SECTION .bss]
StackSpace resb 2*1024
StackTop:

[SECTION .text]
global _start

_start:
mov esp, StackTop

sgdt [gdt_ptr]
call cstart
lgdt [gdt_ptr] 

jmp SELECTOR_KERNEL_CS:cstart 

csinit:

push 0
popfd

hlt