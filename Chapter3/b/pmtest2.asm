; file:pmtest1.asm
; 编译方法: nasm pmtest1.asm -o pmtest1.bin

%include "pm.inc"

org 0100h
jmp LABEL_BEGIN

[SECTION .gdt]
;建立GDT表
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
GdtPtr dw GdtLen-1 ;GDT 界限
       dd 0 ;GDT 基地址

;GDT selector
SelectorCode32 equ LABEL_DESC_CODE32 - LABEL_GDT
SelectorVideo equ LABEL_DESC_VIDEO - LABEL_GDT
SelectorNormal equ LABEL_DESC_NORMAL - LABEL_GDT
SelectorCode16 equ LABEL_DESC_CODE16 - LABEL_GDT
SelectorData equ LABEL_DESC_DATA - LABEL_GDT
SelectorStack equ LABEL_DESC_STACK - LABEL_GDT
SelectorTest equ LABEL_DESC_TEST - LABEL_GDT

;end of [SECTION . gdt]

	[SECTION .data1]
	ALIGN 32
	[BITS 32]
LABEL_DATA:
	SPValueInRealMode dw 0
	PMMessage db "in protect mode now. ^_^",0
	OffsetPMMessage equ PMMessage - $$
	StrTest db "ABCDEFGHIJKLMNPQRSTUVWXYZ", 0
	OffsetStrTest equ StrTest - $$
	DataLen equ $ - LABEL_DATA

				; end of [SECTION .data1]


	[SECTION .gs]
	ALIGN 32
	[BITS 32]
LABEL_STACK:
	times 512 db 0
	TopOfStack equ $ - LABEL_STACK - 1
				; end of [SECTION .gs]

;*****************************************

[SECTION .s16]
[BITS 16]
LABEL_BEGIN:
mov ax,cs
mov ds,ax
mov es,ax
mov ss,ax
mov sp,0100h

mov [LABEL_GO_BACK_TO_REAL + 3], ax
mov [SPValueInRealMode], sp

;init 初始化16位代码段描述符 descriptor
mov ax, cs
movzx eax, ax
shl eax, 4
add eax, LABEL_SEG_CODE16
mov word [LABEL_DESC_CODE16 + 2] , ax
shr eax, 16
mov byte [LABEL_DESC_CODE16 + 4], al
mov byte [LABEL_DESC_CODE16 + 17], ah

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

;初始化数据段描述符
xor eax,eax
mov ax,ds
shl eax, 4
add eax, LABEL_DATA
mov word [LABEL_DESC_DATA + 2], ax
shr eax, 16
mov byte [LABEL_DESC_DATA + 4], al
mov byte [LABEL_DESC_DATA + 7], ah

 ;初始化堆栈段描述符
 xor eax, eax
 mov ax, ds
 shl eax, 4
 add eax, LABEL_STACK
 mov word [LABEL_DESC_STACK + 2], ax
 shr eax, 16
 mov byte [LABEL_DESC_STACK + 4], al
 mov byte [LABEL_DESC_STACK + 7], ah

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
or eax, 1
mov cr0, eax


;进入保护模式
jmp dword SelectorCode32:0

;从保护模式回到实模式
LABEL_REAL_ENTRY:

mov ax, cx
mov ds, ax
mov es, ax
mov ss ,ax

mov sp, [SPValueInRealMode]
in al, 92h
and al, 1111101b
out 92h, al

sti

mov ax, 4c00h
int 21h

;END of [SECTION .16]


[SECTION .s32]
[BITS 32]

LABEL_SEG_CODE32:
	mov ax,SelectorData
	mov ds,ax		;ds -> data address
	mov ax,SelectorTest
	mov es,ax		;es <- test codes
	mov ax, SelectorVideo
	mov gs, ax		;gs <- videoSection address

    mov ax, SelectorStack
    mov ss, ax

    mov esp, TopOfStack

;显示一个字符串
	mov ah,0ch
    xor esi,esi
    xor edi,edi
    mov esi,OffsetPMMessage
    mov edi, (80 * 10 + 0) * 2
    cld

    .1:
    lodsb
    test al,al
    jz .2
    mov [gs:edi], ax
    add edi, 2
    jmp .1

    .2:
    call DispReturn
    call TestRead
    call TestWrite
    call TestRead

    jmp SelectorCode16: 0


;**************************************
;        TestRead
;***************************************

TestRead:
    xor esi,esi
    mov ecx,8

    .loop:
    mov al, [es: esi]
    call DispAL
    inc esi
    loop .loop

    call DispReturn
    ret

;***********************************
TestWrite:
    push esi
    push edi
    xor esi, esi
    xor edi, edi
    mov esi, OffsetStrTest
    cld

    .1:
    lodsb
    test al, al
    jz .2
    mov [es: edi], al
    inc edi
    jmp .1

    .2:
    pop edi
    pop esi

    ret

;**********************
DispAL:
    push ecx
    push edx
    mov ah, 0CH
    mov dl, al
    shr al, 4
    mov ecx, 2

    .begin:
    and al,01111b
    cmp al, 9
    ja .1
    add al, '0'
    ja .2

    .1:
    sub al, 0Ah
    add al, 'A'

    .2:
    mov [gs: edi], ax
    add edi , 2
    mov al, dl
    loop .begin
    add edi,2
    pop edx
    pop ecx
    ret

;************************
DispReturn:
 push eax;
 push ebx;
 mov eax, edi;
 mov bl, 160
 div bl
 and eax, 0FFH
 inc eax
 mov bl, 160
 mul bl
 mov edi, eax
 pop ebx
 pop eax

 ret
;**************************************

SegCode32Len equ $ - LABEL_SEG_CODE32


[SECTION .s16code]
ALIGN 32
[BITS 16]
LABEL_SEG_CODE16:
;跳回实模式
mov ax, SelectorNormal
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

mov eax,cr0
and al, 1111110b
mov cr0, eax

LABEL_GO_BACK_TO_REAL:
jmp 0:LABEL_REAL_ENTRY

Code16Len equ $ - LABEL_SEG_CODE16

;end of [SECTION .s16code]
