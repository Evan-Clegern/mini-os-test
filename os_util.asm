BITS 64
CPU X64

; Can also use  _ $ # @ ~ . ?
; Use custom naming scheme!
; ~  for sub-namespaces
; .  for member functions of namespaces or objects
; _  for overrides, etc
; #  for member variables of namespaces or objects

GLOBAL OS~UTIL~TERM.SET_COLOR:FUNCTION
GLOBAL OS~UTIL~TERM.PUT@:FUNCTION
GLOBAL OS~UTIL~TERM.PUTC:FUNCTION
GLOBAL OS~UTIL.STRLEN:FUNCTION
GLOBAL OS~UTIL~TERM.PUTS:FUNCTION

GLOBAL OS~UTIL~TERM#COLOR:DATA
GLOBAL OS~UTIL~TERM.CURSOR#COL:DATA
GLOBAL OS~UTIL~TERM.CURSOR#ROW:DATA


OS~UTIL~TERM#COLOR DB 0
OS~UTIL~TERM.CURSOR#COL DB 0
OS~UTIL~TERM.CURSOR#ROW DB 0


; Takes: None (uses #COL and #ROW)
; Clobbers: DX
; Returns: Offset for specified position in memory (DX)
; Provides the memory offset for the specified position to place a character for printing.
;
OS~UTIL~TERM.GET_TERMBUFF_IDX:
	PUSH RAX
	XOR RAX, RAX
	MOV DL, BYTE [OS~UTIL~TERM.CURSOR#COL]
	MOV DH, BYTE [OS~UTIL~TERM.CURSOR#ROW]
	SHL DH, 1
	MOV AL, 80
	MUL DL
	MOV DL, AL
	SHL DL, 1
	ADD DL, DH
	MOV DH, 0
	POP RAX
	RET

; Takes: Foreground VGA Color (DH), Background VGA Color (DL)
; Clobbers: None
; Returns: None
; Sets the specified colors of the terminal.
;
OS~UTIL~TERM.SET_COLOR:
	SHL DL, 4
	OR DL, DH
	MOV BYTE [OS~UTIL~TERM#COLOR], DL
	RET

; Takes: Y position (DL), X position (DH), Character (AL)
; Clobbers: RBX
; Returns: None
; Places a UTF-8 character at the specified position.
;
; movzx bigger, smaller  - UNSIGNED extension
; movsx bigger, smaller  - SIGNED extension
OS~UTIL~TERM.PUT@:
	MOV BYTE [OS~UTIL~TERM.CURSOR#ROW], DL
	MOV BYTE [OS~UTIL~TERM.CURSOR#COL], DH
	CALL OS~UTIL~TERM.GET_TERMBUFF_IDX
	XOR RBX, RBX
	MOV BX, DX
	MOV DL, BYTE [OS~UTIL~TERM#COLOR]
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
	CMP AL, 0x0A
	JE .newl
	
	CALL OS~UTIL~TERM.GET_TERMBUFF_IDX
	XOR RBX, RBX
	MOV BX, DX
	MOV DL, BYTE [OS~UTIL~TERM#COLOR]
	
	INC AL
	
	MOV BYTE [0xB8000 + RBX], AL
	MOV BYTE [0xB8001 + RBX], DL
	
	INC BYTE [OS~UTIL~TERM.CURSOR#ROW]
	CMP BYTE [OS~UTIL~TERM.CURSOR#ROW], 80
	JNE .moved
	.newl:
		MOV BYTE [OS~UTIL~TERM.CURSOR#ROW], 0
		INC BYTE [OS~UTIL~TERM.CURSOR#COL]
		CMP BYTE [OS~UTIL~TERM.CURSOR#COL], 25
		JNE .moved
		MOV BYTE [OS~UTIL~TERM.CURSOR#COL], 0
	
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
		CALL OS~UTIL~TERM.PUTC
		
		INC RCX
		CMP RCX, RDX
		JNE .LOOP
	POP RAX
	POP RCX
	RET
