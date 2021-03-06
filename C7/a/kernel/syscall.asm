%include "sconst.inc"

INT_VECTOR_SYS_CALL equ 0x90
;_NR_get_ticks equ 0
;_NR_write equ 1
_NR_sendrec equ 0
_NR_printx	    equ 1



global sendrec;
global printx;
bits 32
[section .text]

get_ticks:
	mov eax, _NR_get_ticks
	int INT_VECTOR_SYS_CALL
	ret

write:
	mov eax, _NR_write
	mov ebx, [esp + 4]
	mov ecx, [esp + 8]
	int INT_VECTOR_SYS_CALL
	ret
; ====================================================================================
;                  sendrec(int function, int src_dest, MESSAGE* msg);
; ====================================================================================
; Never call sendrec() directly, call send_recv() instead.
sendrec:
	mov	eax, _NR_sendrec
	mov	ebx, [esp + 4]	; function
	mov	ecx, [esp + 8]	; src_dest
	mov	edx, [esp + 12]	; p_msg
	int	INT_VECTOR_SYS_CALL
	ret

	; ====================================================================================
	;                          void printx(char* s);
	; ====================================================================================
	printx:
		mov	eax, _NR_printx
		mov	edx, [esp + 4]
		int	INT_VECTOR_SYS_CALL
		ret
