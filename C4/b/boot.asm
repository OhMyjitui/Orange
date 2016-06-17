;find loader.bin 

mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, BaseOfStack

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
mov si, LoaderFileName
jmp LABEL_SEARCH_FOR_LOADERBIN

LABEL_NO_LOADERBIN: 
mov dh, 2 
call Disptr 

%ifdef _BOOT_DEBUG_
mov ax, 4c00h
int 21
%else 
jmp $
%endif 

LABEL_FILENAME_FOUND: 
jmp $
											 