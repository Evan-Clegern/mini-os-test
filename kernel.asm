BITS 64
CPU X64

%include "os_util.txt.asm"



section .data
	BOOTCHAR DB 'x'
	BOOTSTR DB  "I think it's doing something?", 0x0A, 0x00
	BOOTSTR.len EQU $ - BOOTSTR
	

section .text
	global Kernel_Start:function
	Kernel_Start:
		OS~UTIL~TERM.SET_COLOR_M COLOR_MAGENTA, COLOR_BLACK
		MOV AL, 'X'
		CALL OS~UTIL~TERM.PUTC
		MOV AL, '!'
		CALL OS~UTIL~TERM.PUTC
		MOV AL, 0x0a
		CALL OS~UTIL~TERM.PUTC
		MOV RSI, BOOTSTR
		MOV RDX, BOOTSTR.len
		CALL OS~UTIL~TERM.PUTS
		JMP $
