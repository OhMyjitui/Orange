; file:pmtest1.asm
; 编译方法: nasm pmtest1.asm -o pmtest1.bin

%include "pm.inc"

org 07c00h
jmp LABEL_BEGIN

[SECTION .gdt]
;GDT FOUND
;

LABEL_GDT: Descriptor 0,0,0;
LABEL_DESC_NORMAL Descriptor 0, 0ffffh, DA_DRW		       ;
LABEL_DESC_CODE32: Descriptor 0, SegCode32Len -1, DA_C + DA_32;
LABEL_DESC_CODE16: Descriptor 0, 0ffffh, DA_C		      ;
LABEL_DESC_DATA: Descriptor 0, DataLen-1, DA_DRW	      ;
LABEL_DESC_STACK: Descriptor 0, TopOfStack, DA_DRWA+DA_32     ;
LABEL_DESC_TEST : Descriptor 0500000h, 0fffh, DA_DRW	      ;
LABEL_DESC_VIDEO: Descriptor 0B8000h, 0ffffh, DA_DRW;

GdtLen equ $-LABEL_GDT ; length of GDT
GdtPtr dw GdtLen-1
       dd 0

;GDT selector
SelectorCode32 equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo equ LABEL_DESC_VIDEO - LABEL_GDT
SelectorNormal equ LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode16 equ LABEL_DESC_CODE16 - LABEL_GDT
SelectorData equ LABEL_DESC_DATA - LABEL_GDT
SelectorStack equ LABEL_DESC_STACK - LABEL_GDT
SelectorTest equ LABEL_DESC_TEST - LABEL_GDT
	
;end of [SECTION . gdt]

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0100h

;init 初始化32位代码段描述符 descriptor
;将LABEL_SEG_CODE32地址信息 移动到描述符中

xor eax,eax
mov ax,cs
shl eax,4
add eax,LABEL_SEG_CODE32
mov word [LABEL_DESC_CODE32 + 2], ax
shr eax,16
mov byte [LABEL_DESC_CODE32 + 4], al
mov byte [LABEL_DESC_CODE32 + 7], ah

;为加载GDTR作准备
xor eax,eax
mov ax,ds
shl eax,4
add eax, LABEL_GDT
mov dword [GdtPtr + 2], eax

;load GDTR
lgdt [GdtPtr]

;close interupt
cli

; open A20
in al,92h
or al,00000010b
out 92h,al

;
mov eax,cr0
xor eax, 1
mov cr0, eax

jmp dword SelectorCode32:0

;END of SECTION .16

[SECTION .s32]
[BITS 32]
LABEL_SEG_CODE32:
mov ax,SelectorVideo
mov gs,ax

mov edi,(80 * 11 + 79) * 2
mov ah,0Ch
mov al,'p'
mov [gs:edi],ax

jmp $

SegCode32Len equ $ - LABEL_SEG_CODE32


;end of [SECTION .s32]

	[SECTION .data1]
	ALIGN 32
	[BITS 32]
LABEL_DATA:
	SPValueInRaealMode dw 0
	PMMessage db "in protect mode now. ^_^",0
	OffsetPMMessage equ PMMessage - $$
	StrtTest db "ABCDEFGHIJKLMNPQRSTUVWXYZ", 0
	OffsetStrTest equ StrTest - $$
	DataLen equ $ - LABEL_DATA

				; end of [SECTION .data1]


	[SECTION .gs]
	ALIEN 32
	[BITS 32]
LABEL_STACK:
	times 512 db 0
	TopOfStack equ $ - LABEL_STACK - 1
				; end of [SECTION .gs]
	
