; ==========================================
; pmtest2.asm
; 编译方法：nasm pmtest2.asm -o pmtest2.com
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明

PageDirBase equ 200000h
PageTblBase equ 201000h

org	0100h
	jmp	LABEL_BEGIN

[SECTION .gdt]
; GDT
;                            段基址,       段界限, 属性
LABEL_GDT:           Descriptor 0,              0, 0     		; 空描述符
LABEL_DESC_NORMAL:   Descriptor 0,         0ffffh, DA_DRW		; Normal 描述符
LABEL_DESC_PAGE_DIR: Descriptor PageDirBase, 4095, DA_DRW;Page Directory
LABEL_DESC_PAGE_TBL: Descriptor PageTblBase, 1023, DA_DRW| DA_LIMIT_4K;Page Tables
LABEL_DESC_CODE32:   Descriptor 0, SegCode32Len-1, DA_C+DA_32		; 非一致代码段, 32
LABEL_DESC_CODE16:   Descriptor 0,         0ffffh, DA_C			; 非一致代码段, 16
LABEL_DESC_DATA:     Descriptor 0,      DataLen-1, DA_DRW		; Data
LABEL_DESC_STACK:    Descriptor 0,     TopOfStack, DA_DRWA + DA_32	; Stack, 32 位
LABEL_DESC_VIDEO:    Descriptor 0B8000h,   0ffffh, DA_DRW		; 显存首地址
; GDT 结束

GdtLen		equ	$ - LABEL_GDT	; GDT长度
GdtPtr		dw	GdtLen - 1	; GDT界限
		dd	0		; GDT基地址

; GDT 选择子
SelectorNormal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
SelectorPageDir		equ	LABEL_DESC_PAGE_DIR	- LABEL_GDT
SelectorPageTbl		equ	LABEL_DESC_PAGE_TBL	- LABEL_GDT
SelectorCode32		equ	LABEL_DESC_CODE32	- LABEL_GDT
SelectorCode16		equ	LABEL_DESC_CODE16	- LABEL_GDT
SelectorData		equ	LABEL_DESC_DATA		- LABEL_GDT
SelectorStack		equ	LABEL_DESC_STACK	- LABEL_GDT
SelectorVideo		equ	LABEL_DESC_VIDEO	- LABEL_GDT
; END of [SECTION .gdt]


[SECTION .data1]	 ; 数据段
ALIGN	32
[BITS	32]
LABEL_DATA:
; 实模式下使用这些符号
; 字符串
_szPMMessage:			db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0	; 进入保护模式后显示此字符串
_szMemChkTitle:			db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; 进入保护模式后显示此字符串
_szRAMSize			db	"RAM size:", 0
_szReturn			db	0Ah, 0
; 变量
_wSPValueInRealMode		dw	0
_dwMCRNumber:			dd	0	; Memory Check Result
_dwDispPos:			dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_dwMemSize:			dd	0
_ARDStruct:			; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:		dd	0

_MemChkBuf:	times	256	db	0

; 保护模式下使用这些符号
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle		equ	_szMemChkTitle	- $$
szRAMSize		equ	_szRAMSize	- $$
szReturn		equ	_szReturn	- $$
dwDispPos		equ	_dwDispPos	- $$
dwMemSize		equ	_dwMemSize	- $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct	- $$
	dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
	dwLengthLow	equ	_dwLengthLow	- $$
	dwLengthHigh	equ	_dwLengthHigh	- $$
	dwType		equ	_dwType		- $$
MemChkBuf		equ	_MemChkBuf	- $$

DataLen			equ	$ - LABEL_DATA
; END of [SECTION .data1]	


; 全局堆栈段
[SECTION .gs]
ALIGN	32
[BITS	32]
LABEL_STACK:
	times 512 db 0

TopOfStack	equ	$ - LABEL_STACK - 1

; END of [SECTION .gs]


[SECTION .s16]
[BITS	16]
LABEL_BEGIN:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	mov	[LABEL_GO_BACK_TO_REAL+3], ax
	mov	[_wSPValueInRealMode], sp
	
	;得到内存数
	mov ebx, 0
	mov di, _MemChkBuf
	.loop:
	mov eax, 0E820H
	mov ecx, 20
	mov edx, 0543D4150H
	int 15h
	jc LABEL_MEM_CHK_FAIL
	add di, 20
	inc dword [_dwMCRNumber]
	cmp ebx, 0
	jne .loop
	jmp LABEL_MEM_CHK_OK
	
	LABEL_MEM_CHK_FAIL:
	mov dword [_dwMCRNumber], 0
	
	LABEL_MEM_CHK_OK:
	; 初始化 16 位代码段描述符
	
	mov	ax, cs
	movzx	eax, ax
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah

	; 初始化 32 位代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE32 + 4], al
	mov	byte [LABEL_DESC_CODE32 + 7], ah

	; 初始化数据段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; 为加载 GDTR 作准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT		; eax <- gdt 基地址
	mov	dword [GdtPtr + 2], eax	; [GdtPtr + 2] <- gdt 基地址

	; 加载 GDTR
	lgdt	[GdtPtr]

	; 关中断
	cli

	; 打开地址线A20
	in	al, 92h
	or	al, 00000010b
	out	92h, al

	; 准备切换到保护模式
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 真正进入保护模式
	jmp	dword SelectorCode32:0	; 执行这一句会把 SelectorCode32 装入 cs, 并跳转到 Code32Selector:0  处

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LABEL_REAL_ENTRY:		; 从保护模式跳回到实模式就到了这里
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax

	mov	sp, [_wSPValueInRealMode]

	in	al, 92h		; `.
	and	al, 11111101b	;  | 关闭 A20 地址线
	out	92h, al		; /

	sti			; 开中断

	mov	ax, 4c00h	; `.
	int	21h		; /  回到 DOS
; END of [SECTION .s16]


[SECTION .s32]; 32 位代码段. 由实模式跳入.
[BITS	32]

LABEL_SEG_CODE32:
	call SetupPaging
	
	mov	ax, SelectorData
	mov	ds, ax			; 数据段选择子
	mov	ax, SelectorData
	mov	es, ax
	mov	ax, SelectorVideo
	mov	gs, ax			; 视频段选择子

	mov	ax, SelectorStack
	mov	ss, ax			; 堆栈段选择子

	mov	esp, TopOfStack


	; 下面显示一个字符串
	push	szPMMessage
	call	DispStr
	add	esp, 4

	push	szMemChkTitle
	call	DispStr
	add	esp, 4


	;call	DispMemSize	
;	
	; 到此停止
	jmp	SelectorCode16:0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetupPaging:

	;init Page Directory
        mov ax, SelectorPageDir
		mov es, ax
		mov ecx,1024
		xor edi, edi 
		xor eax, eax
		mov eax, PageTblBase| PG_P| PG_USU| PG_RWW
		
		.1:
		stosd
		add eax, 4096
		loop .1
		
		;init page tabel
		mov ax, SelectorPageTbl
		mov es, ax
		mov ecx, 1024*1024
		xor edi, edi
		xor eax, eax
		mov eax, PG_P| PG_USU| PG_RWW
		
		
		.2:
		stosd
		add eax, 4096
		loop .2
		
		add eax, PageDirBase
		mov cr3, eax
		mov eax, cr0
		or eax, 80000000h
		mov cr0, eax
		jmp short .3
		
		.3:
		nop
		ret
		

DispMemSize:
        push esi
		push edi
		push ecx
		
		mov esi, MemChkBuf
		mov ecx, [dwMCRNumber]
		
		.loop:
		mov edx, 5
		mov edi, ARDStruct
		
		.1:
		push dword [esi]
		call DispInt
		pop eax
		stosd
		add esi, 4
		dec edx 
		cmp edx, 0 
		call DispReturn 
		cmp dword [dwType], 1
		jne .2
		mov eax, [dwBaseAddrLow]
		add eax, [dwLengthLow]
		cmp eax, [dwMemSize]
		jb .2
		mov [dwMemSize], eax
		
		
		.2:
		loop .loop
		
		call DispReturn 
		push szRAMSize 
		call DispStr 
		add esp, 4
		
		push dword [dwMemSize] 
		call DispInt
		add esp, 4
		
		push dword [dwMemSize]
		call DispInt
		add esp, 4
		
		pop ecx
		pop edi 
		pop esi 
		ret
		
	%include "lib.inc"
		
		
		
SegCode32Len	equ	$ - LABEL_SEG_CODE32
; END of [SECTION .s32]		
		

; 16 位代码段. 由 32 位代码段跳入, 跳出后到实模式
[SECTION .s16code]
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	; 跳回实模式:
	mov	ax, SelectorNormal
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	mov	eax, cr0
	and     eax, 7FFFFFFEh          ; PE=0, PG=0
	mov	cr0, eax

LABEL_GO_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; 段地址会在程序开始处被设置成正确的值

Code16Len	equ	$ - LABEL_SEG_CODE16

; END of [SECTION .s16code]
