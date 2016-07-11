
;%define	_BOOT_DEBUG_	; �� Boot Sector ʱһ��������ע�͵�!�����д򿪺��� nasm Boot.asm -o Boot.com ����һ��.COM�ļ����ڵ���

%ifdef	_BOOT_DEBUG_
	org  0100h			; ����״̬, ���� .COM �ļ�, �ɵ���
%else
	org  07c00h			; Boot ״̬, Bios ���� Boot Sector ���ص� 0:7C00 ������ʼִ��
%endif

;================================================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack		equ	0100h	; ����״̬�¶�ջ����ַ(ջ��, �����λ����͵�ַ����)
%else
BaseOfStack		equ	07c00h	; Boot״̬�¶�ջ����ַ(ջ��, �����λ����͵�ַ����)
%endif

BaseOfLoader		equ	09000h	; LOADER.BIN �����ص���λ�� ----  �ε�ַ
OffsetOfLoader		equ	0100h	; LOADER.BIN �����ص���λ�� ---- ƫ�Ƶ�ַ

RootDirSectors		equ	14	; ��Ŀ¼ռ�ÿռ�
SectorNoOfRootDirectory	equ	19	; Root Directory �ĵ�һ��������
SectorNoOfFAT1		equ	1	; FAT1 �ĵ�һ�������� = BPB_RsvdSecCnt
DeltaSectorNo		equ	17	; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
					; �ļ��Ŀ�ʼSector�� = DirEntry�еĿ�ʼSector�� + ��Ŀ¼ռ��Sector��Ŀ + DeltaSectorNo
;================================================================================================

	jmp short LABEL_START		; Start to boot.
	nop				; ��� nop ������

	; ������ FAT12 ���̵�ͷ
	BS_OEMName	DB 'ForrestY'	; OEM String, ���� 8 ���ֽ�
	BPB_BytsPerSec	DW 512		; ÿ�����ֽ���
	BPB_SecPerClus	DB 1		; ÿ�ض�������
	BPB_RsvdSecCnt	DW 1		; Boot ��¼ռ�ö�������
	BPB_NumFATs	DB 2		; ���ж��� FAT ��
	BPB_RootEntCnt	DW 224		; ��Ŀ¼�ļ������ֵ
	BPB_TotSec16	DW 2880		; �߼���������
	BPB_Media	DB 0xF0		; ý��������
	BPB_FATSz16	DW 9		; ÿFAT������
	BPB_SecPerTrk	DW 18		; ÿ�ŵ�������
	BPB_NumHeads	DW 2		; ��ͷ��(����)
	BPB_HiddSec	DD 0		; ����������
	BPB_TotSec32	DD 0		; ��� wTotalSectorCount �� 0 �����ֵ��¼������
	BS_DrvNum	DB 0		; �ж� 13 ����������
	BS_Reserved1	DB 0		; δʹ��
	BS_BootSig	DB 29h		; ��չ������� (29h)
	BS_VolID	DD 0		; �����к�
	BS_VolLab	DB 'OrangeS0.02'; ���, ���� 11 ���ֽ�
	BS_FileSysType	DB 'FAT12   '	; �ļ�ϵͳ����, ���� 8���ֽ�  

;find loader.bin 
LABEL_START:

mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, BaseOfStack

	; ����
	mov	ax, 0600h		; AH = 6,  AL = 0h
	mov	bx, 0700h		; �ڵװ���(BL = 07h)
	mov	cx, 0			; ���Ͻ�: (0, 0)
	mov	dx, 0184fh		; ���½�: (80, 50)
	int	10h			; int 10h

	mov	dh, 0			; "Booting  "
	call	DispStr			; ��ʾ�ַ���

;���̸�λ 
xor ah,ah
xor dl, dl
int 13h

;Ѱ�� loader.bin
;wSectorNoҪ��ȡ��������
; SectorNoOfRootDirectory rootDirectory�ĵ�һ������
mov word [wSectorNo], SectorNoOfRootDirectory 


LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
;�жϸ�Ŀ¼ȥ�ǲ����Ѿ����� ������ת�� LABEL_NO_LOADERBIN
; wRootDirSizeForLoop root Directory ռ�õ�������
cmp word [wRootDirSizeForLoop], 0
jz LABEL_NO_LOADERBIN
dec word [wRootDirSizeForLoop]

; BaseOfLoader loaderbin�����ص��Ķε�ַ
;OffsetOfLoader loaderbin�����ص���ƫ�Ƶ�ַ
mov ax, BaseOfLoader
mov es, ax
mov bx, OffsetOfLoader
mov ax, [wSectorNo]
mov cl, 1
call ReadSector

mov si, LoaderFileName
mov di, OffsetOfLoader 
cld 
mov dx, 10h 

;ÿ������512�ֽ� ÿ����Ŀ32�ֽ� 
;loop 16ci
LABEL_SEARCH_FOR_LOADERBIN:
;�������һ��Sector ��ת����һ��Sector
cmp dx, 0
jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR 
dec dx
mov cx, 11 

LABEL_CMP_FILENAME:
;�Ƚ��ǲ���loader.bin
cmp cx, 0
jz LABEL_FILENAME_FOUND
dec cx 
lodsb
cmp al, byte [es :di]
jz LABEL_GO_ON
jmp LABEL_DIFFERENT

LABEL_GO_ON:
inc di
jmp LABEL_CMP_FILENAME

LABEL_DIFFERENT:
;����loader.bin 
;di += 20h ָ����һ����Ŀ 
and di, 0FFE0h
add di, 20h

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
mov si, LoaderFileName
jmp LABEL_SEARCH_FOR_LOADERBIN

LABEL_NO_LOADERBIN: 
mov dh, 2 
call DispStr 

%ifdef _BOOT_DEBUG_
mov ax, 4c00h
int 21
%else 
jmp $DeltaSectorNo
%endif 

LABEL_FILENAME_FOUND: 
;jmp $
	mov	ax, RootDirSectors
	and	di, 0FFE0h		; di -> ��ǰ��Ŀ�Ŀ�ʼ
	add	di, 01Ah		; di -> �� Sector
	mov	cx, word [es:di]
	push	cx			; ����� Sector �� FAT �е����
	add	cx, ax
	add	cx, DeltaSectorNo	; cl <- LOADER.BIN����ʼ������(0-based)
	mov	ax, BaseOfLoader
	mov	es, ax			; es <- BaseOfLoader
	mov	bx, OffsetOfLoader	; bx <- OffsetOfLoader
	mov	ax, cx			; ax <- Sector ��

LABEL_GOON_LOADING_FILE:
	push	ax			; `.
	push	bx			;  |
	mov	ah, 0Eh			;  | ÿ��һ���������� "Booting  " ����
	mov	al, '.'			;  | ��һ����, �γ�������Ч��:
	mov	bl, 0Fh			;  | Booting ......
	int	10h			;  |
	pop	bx			;  |
	pop	ax			; /

	mov	cl, 1
	call	ReadSector
	pop	ax			; ȡ���� Sector �� FAT �е����
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax			; ���� Sector �� FAT �е����
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	mov	dh, 1			; "Ready."
	call	DispStr			; ��ʾ�ַ���

; *****************************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; ��һ����ʽ��ת���Ѽ��ص���
						; ���е� LOADER.BIN �Ŀ�ʼ����
						; ��ʼִ�� LOADER.BIN �Ĵ��롣
						; Boot Sector ��ʹ�����˽���
; *****************************************************************************************************
			

; *****************************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; ��һ����ʽ��ת���Ѽ��ص���
						; ���е� LOADER.BIN �Ŀ�ʼ����
						; ��ʼִ�� LOADER.BIN �Ĵ��롣
						; Boot Sector ��ʹ�����˽���
; *****************************************************************************************************



;============================================================================
;����
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory ռ�õ�������, ��ѭ���л�ݼ�����.
wSectorNo		dw	0		; Ҫ��ȡ��������
bOdd			db	0		; ��������ż��

;============================================================================
;�ַ���
;----------------------------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	; LOADER.BIN ֮�ļ���
; Ϊ�򻯴���, ����ÿ���ַ����ĳ��Ⱦ�Ϊ MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "; 9�ֽ�, �������ÿո���. ��� 0
Message1		db	"Ready.   "; 9�ֽ�, �������ÿո���. ��� 1
Message2		db	"No LOADER"; 9�ֽ�, �������ÿո���. ��� 2
;============================================================================
;----------------------------------------------------------------------
; ������: DispStr
;----------------------------------------------------------------------------
; ����:
;	��ʾһ���ַ���, ������ʼʱ dh ��Ӧ�����ַ������(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax			; ��
	mov	ax, ds			; �� ES:BP = ����ַ
	mov	es, ax			; ��
	mov	cx, MessageLength	; CX = ������
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 07h)
	mov	dl, 0
	int	10h			; int 10h
	ret

;----------------------------------------------------------------------------
; ������: ReadSector
;----------------------------------------------------------------------------
; ����:
;	�ӵ� ax �� Sector ��ʼ, �� cl �� Sector ���� es:bx ��
ReadSector:
	; -----------------------------------------------------------------------
	; �������������������ڴ����е�λ�� (������ -> �����, ��ʼ����, ��ͷ��)
	; -----------------------------------------------------------------------
	; ��������Ϊ x
	;                           �� ����� = y >> 1
	;       x           �� �� y ��
	; -------------- => ��      �� ��ͷ�� = y & 1
	;  ÿ�ŵ�������     ��
	;                   �� �� z => ��ʼ������ = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; �ٳ������ֽڵĶ�ջ���򱣴�Ҫ����������: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; ���� bx
	mov	bl, [BPB_SecPerTrk]	; bl: ����
	div	bl			; y �� al ��, z �� ah ��
	inc	ah			; z ++
	mov	cl, ah			; cl <- ��ʼ������
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (��ʵ�� y/BPB_NumHeads, ����BPB_NumHeads=2)
	mov	ch, al			; ch <- �����
	and	dh, 1			; dh & 1 = ��ͷ��
	pop	bx			; �ָ� bx
	; ����, "�����, ��ʼ����, ��ͷ��" ȫ���õ� ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; �������� (0 ��ʾ A ��)
.GoOnReading:
	mov	ah, 2			; ��
	mov	al, byte [bp-2]		; �� al ������
	int	13h
	jc	.GoOnReading		; �����ȡ���� CF �ᱻ��Ϊ 1, ��ʱ�Ͳ�ͣ�ض�, ֱ����ȷΪֹ

	add	esp, 2
	pop	bp

	ret

GetFATEntry:
push es
push bx
push ax
mov ax, BaseOfLoader  ;BaseOfLoader��������4K�ռ���FAT 
sub ax, 0100h
mov es, ax
pop ax
mov byte [bOdd], 0	;[bOdd] �ж�����ż 
mov bx, 3           ;dx:ax = ax * 3
mul bx
mov bx, 2            ;dx:ax / 2     ��>>ax  ���� >> dx  
div bx 
cmp dx, 0 
jz LABEL_EVEN 
mov byte [bOdd], 1 

LABEL_EVEN:		
;ax����FATENTRY��FAT��ƫ���� 
;�������FATEntry���ĸ����� 
xor dx, dx                  
mov bx, [BPB_BytsPerSec]     ;dx: ax / BPB_BytsPerSec
div bx                       ;FATEntry�������������FAT��������>>ax  
push dx                      ;�������ڵ�ƫ�� >> dx  
mov bx, 0                    ;es :bx = (BaseOfLoader-100):00
add ax, SectorNoOfFAT1       ;ax��FATEntry������
mov cl, 2 
call ReadSector               ;��FATEntry�������� 
pop dx 
add bx, dx 
mov ax, [es: bx] 
cmp byte [bOdd], 1 
jnz LABEL_EVEN_2
shr ax, 4 

LABEL_EVEN_2:
and ax, 0FFFH 

LABEL_GET_GAT_ENRY_OK :
pop bx 
pop es 
ret 


times 	510-($-$$)	db	0	; ���ʣ�µĿռ䣬ʹ���ɵĶ����ƴ���ǡ��Ϊ512�ֽ�
dw 	0xaa55				; ������־
