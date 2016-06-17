
;%define	_BOOT_DEBUG_	; 做 Boot Sector 时一定将此行注释掉!将此行打开后用 nasm Boot.asm -o Boot.com 做成一个.COM文件易于调试

%ifdef	_BOOT_DEBUG_
	org  0100h			; 调试状态, 做成 .COM 文件, 可调试
%else
	org  07c00h			; Boot 状态, Bios 将把 Boot Sector 加载到 0:7C00 处并开始执行
%endif

;================================================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack		equ	0100h	; 调试状态下堆栈基地址(栈底, 从这个位置向低地址生长)
%else
BaseOfStack		equ	07c00h	; Boot状态下堆栈基地址(栈底, 从这个位置向低地址生长)
%endif

BaseOfLoader		equ	09000h	; LOADER.BIN 被加载到的位置 ----  段地址
OffsetOfLoader		equ	0100h	; LOADER.BIN 被加载到的位置 ---- 偏移地址

RootDirSectors		equ	14	; 根目录占用空间
SectorNoOfRootDirectory	equ	19	; Root Directory 的第一个扇区号
SectorNoOfFAT1		equ	1	; FAT1 的第一个扇区号 = BPB_RsvdSecCnt
DeltaSectorNo		equ	17	; DeltaSectorNo = BPB_RsvdSecCnt + (BPB_NumFATs * FATSz) - 2
					; 文件的开始Sector号 = DirEntry中的开始Sector号 + 根目录占用Sector数目 + DeltaSectorNo
;================================================================================================

	jmp short LABEL_START		; Start to boot.
	nop				; 这个 nop 不可少

	; 下面是 FAT12 磁盘的头
	BS_OEMName	DB 'ForrestY'	; OEM String, 必须 8 个字节
	BPB_BytsPerSec	DW 512		; 每扇区字节数
	BPB_SecPerClus	DB 1		; 每簇多少扇区
	BPB_RsvdSecCnt	DW 1		; Boot 记录占用多少扇区
	BPB_NumFATs	DB 2		; 共有多少 FAT 表
	BPB_RootEntCnt	DW 224		; 根目录文件数最大值
	BPB_TotSec16	DW 2880		; 逻辑扇区总数
	BPB_Media	DB 0xF0		; 媒体描述符
	BPB_FATSz16	DW 9		; 每FAT扇区数
	BPB_SecPerTrk	DW 18		; 每磁道扇区数
	BPB_NumHeads	DW 2		; 磁头数(面数)
	BPB_HiddSec	DD 0		; 隐藏扇区数
	BPB_TotSec32	DD 0		; 如果 wTotalSectorCount 是 0 由这个值记录扇区数
	BS_DrvNum	DB 0		; 中断 13 的驱动器号
	BS_Reserved1	DB 0		; 未使用
	BS_BootSig	DB 29h		; 扩展引导标记 (29h)
	BS_VolID	DD 0		; 卷序列号
	BS_VolLab	DB 'OrangeS0.02'; 卷标, 必须 11 个字节
	BS_FileSysType	DB 'FAT12   '	; 文件系统类型, 必须 8个字节  

;find loader.bin 
LABEL_START:

mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, BaseOfStack

	; 清屏
	mov	ax, 0600h		; AH = 6,  AL = 0h
	mov	bx, 0700h		; 黑底白字(BL = 07h)
	mov	cx, 0			; 左上角: (0, 0)
	mov	dx, 0184fh		; 右下角: (80, 50)
	int	10h			; int 10h

	mov	dh, 0			; "Booting  "
	call	DispStr			; 显示字符串

;软盘复位 
xor ah,ah
xor dl, dl
int 13h

;寻找 loader.bin
;wSectorNo要读取的扇区号
; SectorNoOfRootDirectory rootDirectory的第一个扇区
mov word [wSectorNo], SectorNoOfRootDirectory 


LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
;判断根目录去是不是已经读完 读完跳转到 LABEL_NO_LOADERBIN
; wRootDirSizeForLoop root Directory 占用的扇区数
cmp word [wRootDirSizeForLoop], 0
jz LABEL_NO_LOADERBIN
dec word [wRootDirSizeForLoop]

; BaseOfLoader loaderbin被加载到的段地址
;OffsetOfLoader loaderbin被加载到的偏移地址
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

;每个扇区512字节 每个条目32字节 
;loop 16ci
LABEL_SEARCH_FOR_LOADERBIN:
;如果读完一个Sector 跳转到下一个Sector
cmp dx, 0
jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR 
dec dx
mov cx, 11 

LABEL_CMP_FILENAME:
;比较是不是loader.bin
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
;不是loader.bin 
;di += 20h 指向下一个条目 
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
	and	di, 0FFE0h		; di -> 当前条目的开始
	add	di, 01Ah		; di -> 首 Sector
	mov	cx, word [es:di]
	push	cx			; 保存此 Sector 在 FAT 中的序号
	add	cx, ax
	add	cx, DeltaSectorNo	; cl <- LOADER.BIN的起始扇区号(0-based)
	mov	ax, BaseOfLoader
	mov	es, ax			; es <- BaseOfLoader
	mov	bx, OffsetOfLoader	; bx <- OffsetOfLoader
	mov	ax, cx			; ax <- Sector 号

LABEL_GOON_LOADING_FILE:
	push	ax			; `.
	push	bx			;  |
	mov	ah, 0Eh			;  | 每读一个扇区就在 "Booting  " 后面
	mov	al, '.'			;  | 打一个点, 形成这样的效果:
	mov	bl, 0Fh			;  | Booting ......
	int	10h			;  |
	pop	bx			;  |
	pop	ax			; /

	mov	cl, 1
	call	ReadSector
	pop	ax			; 取出此 Sector 在 FAT 中的序号
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax			; 保存 Sector 在 FAT 中的序号
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	mov	dh, 1			; "Ready."
	call	DispStr			; 显示字符串

; *****************************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; 这一句正式跳转到已加载到内
						; 存中的 LOADER.BIN 的开始处，
						; 开始执行 LOADER.BIN 的代码。
						; Boot Sector 的使命到此结束
; *****************************************************************************************************
			

; *****************************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; 这一句正式跳转到已加载到内
						; 存中的 LOADER.BIN 的开始处，
						; 开始执行 LOADER.BIN 的代码。
						; Boot Sector 的使命到此结束
; *****************************************************************************************************



;============================================================================
;变量
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; Root Directory 占用的扇区数, 在循环中会递减至零.
wSectorNo		dw	0		; 要读取的扇区号
bOdd			db	0		; 奇数还是偶数

;============================================================================
;字符串
;----------------------------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	; LOADER.BIN 之文件名
; 为简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "; 9字节, 不够则用空格补齐. 序号 0
Message1		db	"Ready.   "; 9字节, 不够则用空格补齐. 序号 1
Message2		db	"No LOADER"; 9字节, 不够则用空格补齐. 序号 2
;============================================================================
;----------------------------------------------------------------------
; 函数名: DispStr
;----------------------------------------------------------------------------
; 作用:
;	显示一个字符串, 函数开始时 dh 中应该是字符串序号(0-based)
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax			; ┓
	mov	ax, ds			; ┣ ES:BP = 串地址
	mov	es, ax			; ┛
	mov	cx, MessageLength	; CX = 串长度
	mov	ax, 01301h		; AH = 13,  AL = 01h
	mov	bx, 0007h		; 页号为0(BH = 0) 黑底白字(BL = 07h)
	mov	dl, 0
	int	10h			; int 10h
	ret

;----------------------------------------------------------------------------
; 函数名: ReadSector
;----------------------------------------------------------------------------
; 作用:
;	从第 ax 个 Sector 开始, 将 cl 个 Sector 读入 es:bx 中
ReadSector:
	; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; 保存 bx
	mov	bl, [BPB_SecPerTrk]	; bl: 除数
	div	bl			; y 在 al 中, z 在 ah 中
	inc	ah			; z ++
	mov	cl, ah			; cl <- 起始扇区号
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov	ch, al			; ch <- 柱面号
	and	dh, 1			; dh & 1 = 磁头号
	pop	bx			; 恢复 bx
	; 至此, "柱面号, 起始扇区, 磁头号" 全部得到 ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
.GoOnReading:
	mov	ah, 2			; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret

GetFATEntry:
push es
push bx
push ax
mov ax, BaseOfLoader  ;BaseOfLoader后面流出4K空间存放FAT 
sub ax, 0100h
mov es, ax
pop ax
mov byte [bOdd], 0	;[bOdd] 判断是奇偶 
mov bx, 3           ;dx:ax = ax * 3
mul bx
mov bx, 2            ;dx:ax / 2     商>>ax  余数 >> dx  
div bx 
cmp dx, 0 
jz LABEL_EVEN 
mov byte [bOdd], 1 

LABEL_EVEN:		
;ax中是FATENTRY在FAT中偏移量 
;下面计算FATEntry在哪个扇区 
xor dx, dx                  
mov bx, [BPB_BytsPerSec]     ;dx: ax / BPB_BytsPerSec
div bx                       ;FATEntry所在扇区相对于FAT的扇区号>>ax  
push dx                      ;在扇区内的偏移 >> dx  
mov bx, 0                    ;es :bx = (BaseOfLoader-100):00
add ax, SectorNoOfFAT1       ;ax是FATEntry扇区号
mov cl, 2 
call ReadSector               ;读FATEntry所在扇区 
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


times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55				; 结束标志
