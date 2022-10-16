; v4dump, Amiga rom dump tool for v4map.prg

; exec.library
SysBase			= 4
OpenLibrary		= -552
CloseLibrary	= -414
; dos.library
PutStr			= -948
Open			= -30;
Close			= -36;
Write			= -48;

.text

Init:
	move.l	#StrFilename,Filename	; use default filename "kick.rom"
	cmp.l	#1,d0					; if cmdline is 1 or less characters
	ble.s	.argsdone

	move.l	a0,Filename				; a0 = cmdline
	subq.l	#1,d0					; d0 = cmdline length
	add.l	d0,a0
	move.b	#0,(a0)					; null-terminate in place
.argsdone:
	movem.l	d2/d3/a2/a6,-(sp)		; save non-scratch registers
	bsr.s	Main
	movem.l	(sp)+,d2/d3/a2/a6		; restore non-scratch registers
	rts

Main:
	; open dos.library
	lea		DosLibraryName,a1
	moveq	#36,d0
	movea.l	SysBase,a6
	jsr		OpenLibrary(a6)
	beq		.FailDosLib
	move.l	d0,DosBase

	; open file for writing
	movea.l	DosBase,a6
	move.l	Filename,d1
	move.l	#1006,d2				; MODE_NEWFILE
	jsr		Open(a6)
	tst.l	d0
	beq		.FailOpen
	move.l	d0,FileHandle

	; write extended rom
	move.l	FileHandle,d1
	move.l	#$E00000,d2
	move.l	#$80000,d3
	jsr		Write(a6)

	; write standard rom
	move.l	FileHandle,d1
	move.l	#$F80000,d2
	move.l	#$80000,d3
	jsr		Write(a6)

	; close file
	move.l	FileHandle,d1
	jsr		Close(a6)

	; print success
	move.l	#StrSuccess,d1
	jsr		PutStr(a6)
	move.l	Filename,d1
	jsr		PutStr(a6)
	move.l	#StrNewLine,d1
	jsr		PutStr(a6)

.Exit:
	; close dos.library
	movea.l	DosBase,a1
	movea.l	SysBase,a6
	jsr		CloseLibrary(a6)
	move.l	#0,DosBase
	moveq.l	#0,d0
	rts

.FailDosLib:
	moveq.l	#0,d0
	rts

.FailOpen:
	move.l	#StrFailOpen,d1
	jsr		PutStr(a6)
	move.l	Filename,d1
	jsr		PutStr(a6)
	move.l	#StrNewLine,d1
	jsr		PutStr(a6)
	bsr.s	.Exit


DosLibraryName			dc.b	"dos.library",0
StrFilename				dc.b	"kick.rom",0
StrFailOpen				dc.b	"Failed writing ",0
StrSuccess				dc.b	"Dumped ",0
StrNewLine				dc.b	10,0

.bss
DosBase					ds.l 1
FileHandle				ds.l 1
Filename				ds.l 1
