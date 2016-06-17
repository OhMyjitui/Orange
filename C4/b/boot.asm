;find loader.bin 

mov ax, cs
mov ds, ax
mov es, ax
mov ss, ax
mov sp, BaseOfStack

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
											 