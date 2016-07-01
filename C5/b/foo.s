extern choose

;[section .data]
num1st dd 3
num2nd dd 4

;[section .text]
global _start
global myprint

_start:
    mov        edi,[num1st] 
    mov        esi,[num2nd] 
    call choose

    mov ebx, 0
    mov eax, 1
    int 0X80
    
myprint:
    ;mov edx, [esp + 4]
    ;mov ecx, [esp + 8]

    mov        ecx,edi 
    mov        edx,esi 
    mov ebx, 1
    mov eax, 4
    int 0x80
    ret

