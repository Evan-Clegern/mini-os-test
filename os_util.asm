BITS 64
CPU X64


; Can also use  _ $ # @ ~ . ?
; Use custom naming scheme!
; ~  for sub-namespaces
; .  for member functions of namespaces or objects
; _  for overrides, etc
; #  for member variables of namespaces or objects

GLOBAL OS~UTIL~TERM.SET_VGA_COLOR:FUNCTION
GLOBAL OS~UTIL~TERM.PUT@:FUNCTION
GLOBAL OS~UTIL~TERM.PUTC:FUNCTION
GLOBAL OS~UTIL~TERM.PUTS:FUNCTION
GLOBAL OS~UTIL.STRLEN:FUNCTION


GLOBAL OS~UTIL~TERMXOR:DATA
GLOBAL OS~UTIL~TERM.CURSORX:DATA
GLOBAL OS~UTIL~TERM.CURSORY:DATA

GLOBAL OS~UTIL~TERM#VGA_HEIGHT:DATA
GLOBAL OS~UTIL~TERM#VGA_WIDTH:DATA


OS~UTIL~TERMXOR DB 0
OS~UTIL~TERM.CURSORX DB 0
OS~UTIL~TERM.CURSORY DB 0

OS~UTIL~TERM#VGA_HEIGHT DB 24
OS~UTIL~TERM#VGA_WIDTH DB 80


; Takes: None (uses X and Y variables.)
; Clobbers: DX
; Returns: Offset for specified position in memory (DX)
; Provides the memory offset for the specified position to place a character for printing.
;
OS~UTIL~TERM.GET_TERMBUFF_IDX:
	PUSH RAX
	PUSH RBX
	; index = (y * VGA_WIDTH) + x
	MOVZX BX, BYTE [OS~UTIL~TERM.CURSORX]
	MOVZX DX, BYTE [OS~UTIL~TERM.CURSORY]
	
	MOVZX AX, BYTE [OS~UTIL~TERM#VGA_WIDTH]
	
	; Every entry is a WORD, not a BYTE, in video memory.
	SHL DX, 1
	SHL BX, 1
	
	MUL DX   ; AX * DX
	; Higher-Order in DX, lower-order in AX.
	; This shouldn't result in anything above 2^10, so move AX --> DX.
	MOV DX, AX
	
	; Add the X position.
	ADD DX, BX
	
	POP RBX
	POP RAX
	
	; This new-and-improved version now ACTUALLY covers the 80x25 terminal fully!
	; The newlines don't wrap around!
	
	RET


; Takes: Foreground VGA Color (DH), Background VGA Color (DL)
; Clobbers: None
; Returns: None
; Sets the specified colors of the terminal.
;
OS~UTIL~TERM.SET_VGA_COLOR:
	SHL DL, 4
	OR DL, DH
	MOV BYTE [OS~UTIL~TERMXOR], DL
	RET

; Takes: Y position (DL), X position (DH), Character (AL)
; Clobbers: RBX
; Returns: None
; Places a UTF-8 character at the specified position.
;
; movzx bigger, smaller  - UNSIGNED extension
; movsx bigger, smaller  - SIGNED extension
OS~UTIL~TERM.PUT@:
	MOV BYTE [OS~UTIL~TERM.CURSORY], DL
	MOV BYTE [OS~UTIL~TERM.CURSORX], DH
	CALL OS~UTIL~TERM.GET_TERMBUFF_IDX  ;EDX
	XOR RBX, RBX
	MOV RBX, RDX
	MOV DL, BYTE [OS~UTIL~TERMXOR]  ; color
	INC AL    ;  For some reason, it was turning 'x' into 'w', '5' into '4', etc.
	MOV BYTE [0xB8000 + RBX], AL
	MOV BYTE [0xB8001 + RBX], DL
	RET

; Takes: Character (AL)
; Clobbers: RBX
; Returns: None
; Places a UTF-8 character at the next available position.
;
OS~UTIL~TERM.PUTC:
	PUSH RDX
	; Null byte.
	CMP AL, 0x00
	JE .moved
	; Line Feed byte; preferred newline.
	CMP AL, 0x0A
	JE .newl
	; Carriage Return byte.
	CMP AL, 0x0D
	JE .newl
	
	
	CALL OS~UTIL~TERM.GET_TERMBUFF_IDX
	XOR RBX, RBX
	MOV BX, DX
	MOV DL, BYTE [OS~UTIL~TERMXOR]
	
	
	INC AL
	
	MOV BYTE [0xB8000 + RBX], AL
	MOV BYTE [0xB8001 + RBX], DL
	
	INC BYTE [OS~UTIL~TERM.CURSORX]
	CMP BYTE [OS~UTIL~TERM.CURSORX], 63
	JNE .moved
	.newl:
		MOV BYTE [OS~UTIL~TERM.CURSORX], 0
		INC BYTE [OS~UTIL~TERM.CURSORY]
		CMP BYTE [OS~UTIL~TERM.CURSORY], 25
		JNE .moved
		MOV BYTE [OS~UTIL~TERM.CURSORY], 0
	
	.moved:
		POP RDX
		RET

; Takes: String Pointer (RSI), String Length (RDX)
; Clobbers: None
; Returns: None
; Prints out a full string.
;
OS~UTIL~TERM.PUTS:
	PUSH RCX
	PUSH RAX
	.LOOP:
		MOV AL, BYTE [RSI + RCX]
		
		; Kindly ignore the "unfinished quote" stuff here. NASM has no use for the backslash.
		CMP AL, '\'
		JNE .NOESC
		INC RCX
		MOV AL, BYTE [RSI + RCX]
		CMP AL, 'n'
		JE .ESC_NEW
		CMP AL, "'"
		JE .ESC_SQ
		CMP AL, '"'
		JE .ESC_DQ
		CMP AL, 't'
		JE .ESC_TAB
		CMP AL, '0'
		JE .ESC_NULL
		; If it isn't \n, \', \", \t, or \0, then treat as \
		
		MOV AL, '\'
		JMP .NOESC
		
		.ESC_NEW:
			MOV AL, 0x0A
			JMP .NOESC
		
		.ESC_SQ:
			MOV AL, "'"
			JMP .NOESC
		
		.ESC_DQ:
			MOV AL, '"'
			JMP .NOESC
		
		.ESC_TAB:
			MOV AL, 0x09
			JMP .NOESC
			
		.ESC_NULL:
			MOV AL, 0x00
		
		.NOESC:
			CALL OS~UTIL~TERM.PUTC
		
			INC RCX
			CMP RCX, RDX
			JNE .LOOP
	POP RAX
	POP RCX
	RET
	
