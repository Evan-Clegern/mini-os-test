
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
	stack_bottom RESB 16384  ; 16 kB


section .text
	global _start:function (_start.end - _start)

_start:
	
	CALL Kernel_Start
	
	CLI
	
	.hang:
		HLT
		JMP .hang
	.end:
		RET
