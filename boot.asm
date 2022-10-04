; DO NOT MODIFY!
BITS 64

MALIGN EQU 1 << 0
MEMINFO EQU 1 << 1
FLAGS EQU MALIGN | MEMINFO
MAGIC EQU 0x1BADB002
CHECKSUM EQU -(MAGIC + FLAGS)


EXTERN Kernel_Start

section .multiboot
ALIGN 4
	DD MAGIC
	DD FLAGS
	DD CHECKSUM

section .bss
ALIGN 16
	; protected memory section.
	protect_bottom:
		RESB 4096   ; 4 kiB
	protect_top:
	; global stack.
	stack_bottom:
		RESB 65536  ; 64 kiB
	stack_top:


section .text
	global _start:function (_start.end - _start)

_start:
	
	NOP
	MOV RSP, stack_top
	CALL Kernel_Start
	
	CLI
	
	.hang:
		HLT
		JMP .hang
	.end:
		RET
