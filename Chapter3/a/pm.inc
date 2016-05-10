;描述符的数据结构
;base : dd
;Limit: dd
;Attr: dw

%macro Descriptor 3
       dw %2 & 0FFFFh
       dw %1 & 0FFFFh
       db (%1 >> 16) & 0FFH
       dw ((%2 >> 8) & 0F00H) | (%3 & 0F0FFh)
       db (%1 >> 24) & 0FFH
%endmacro

;Descriptor type
DA_32 equ 4000h

DA_DPL0 equ 00h
DA_DPL1 equ 20h
DA_DPL2 equ 40h
DA_DPL3 equ 60h

;section descriptor type
DA_DR EQU 90h
DA_DRW equ 92h
DA_DRWA equ 93h
DA_C equ 98h
DA_CR equ 9Ah
DA_CCO equ 9ch
DA_CCOR equ 9eh

DA_LDT EQU 82H
DA_TaskGate EQU 85H
DA_386TSS EQU 89H
DA_386CGate EQU 8CH
DA_386IGate EQU 8EH
DA_386TGate EQU 8FH
