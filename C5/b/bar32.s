	.file	"bar.c"
	.section	.rodata
.LC0:
	.string	"the 1st one\n"
.LC1:
	.string	"the 2nd ont\n"
	.text
	.globl	choose
	.type	choose, @function
choose:
.LFB0:
	.cfi_startproc
	pushl	%ebp
	.cfi_def_cfa_offset 8
	.cfi_offset 5, -8
	movl	%esp, %ebp
	.cfi_def_cfa_register 5
	subl	$8, %esp
	movl	8(%ebp), %eax
	cmpl	12(%ebp), %eax
	jl	.L2
	subl	$8, %esp
	pushl	$13
	pushl	$.LC0
	call	myprint
	addl	$16, %esp
	jmp	.L3
.L2:
	subl	$8, %esp
	pushl	$13
	pushl	$.LC1
	call	myprint
	addl	$16, %esp
.L3:
	movl	$0, %eax
	leave
	.cfi_restore 5
	.cfi_def_cfa 4, 4
	ret
	.cfi_endproc
.LFE0:
	.size	choose, .-choose
	.ident	"GCC: (Ubuntu 5.3.1-14ubuntu2) 5.3.1 20160413"
	.section	.note.GNU-stack,"",@progbits
