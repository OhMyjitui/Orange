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
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movl	%edi, -4(%rbp)
	movl	%esi, -8(%rbp)
	movl	-4(%rbp), %eax
	cmpl	-8(%rbp), %eax
	jl	.L2
	movl	$13, %esi
	movl	$.LC0, %edi
	call	myprint
	jmp	.L3
.L2:
	movl	$13, %esi
	movl	$.LC1, %edi
	call	myprint
.L3:
	movl	$0, %eax
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	choose, .-choose
	.ident	"GCC: (Ubuntu 5.3.1-14ubuntu2) 5.3.1 20160413"
	.section	.note.GNU-stack,"",@progbits
