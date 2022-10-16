// ARGSTART.S - example C startup code
// using GEMDOS Extended Argument Specification
// ================================================================
//    |||   Ken Badertscher  (ames!atari!kbad)
//    |||   Atari R&D System Software Engine
//   / | \  #include <disclaimer>

.globl		_main				// external, C entry point
.globl		_argv0				// external, name used for argv[0] if no ARGV
.globl		_stksize			// external, size of application stack
.globl		_basepage			// allocated here, -> program's basepage
.globl		_environ			// allocated here, -> envp[]
.globl		_argvecs			// allocated here, -> argv[]
.globl		_stklimit			// allocated here, -> lower limit of stack

.BSS
_basepage:	ds.l	1
_environ:	ds.l	1
_argvecs:	ds.l	1
_stklimit:	ds.l	1

.TEXT
_start:
	move.l	4(sp),a5			// get basepage
	move.l	a5,_basepage		// save it
	move.l	24(a5),a0			// bss base
	add.l	28(a5),a0			// plus bss size = envp[] base
	move.l	a0,_environ			// save start of envp[]
	move.l	a0,a1				// start of env/arg vectors
	move.l	44(a5),a2			// basepage environment pointer
	tst.b	(a2)				// empty environment?
	beq.s	nargv				// yes, no envp[]
	lea.l	(sp),a4				// use dummy return pc on stack for ARGV test

// --- fill in the envp[] array
nxenv:	
	move.l	a2,(a1)+			// envp[n]
	move.l	a2,a3
nxen1:	
	tst.b	(a2)+
	bne.s	nxen1				// get the end of this variable
	tst.b	(a2)				// end of env?
	beq.s	xenv

// --- check for ARGV
	move.b	(a3)+,-(a4)			// get 1st 4 bytes of this var
	move.b	(a3)+,-(a4)
	move.b	(a3)+,-(a4)
	move.b	(a3)+,-(a4)
	cmp.l	#0x56475241,(a4)+	// is it ARGV?
	bne.s	nxenv
	cmp.b	#0x3d,(a3)			// is it ARGV=?
	bne.s	nxenv
	clr.b	-4(a3)				// ARGV marks the end of our environment
	cmp.b	#127,0x80(a5)		// command line validation?
	bne.s	nargv				// nope... and we're done with the env.

// --- got an ARGV=, create argv[] array
	clr.l	(a1)+				// terminate envp[]
	move.l	a1,_argvecs			// save base of argv[]
nxarg:	
	move.l	a2,(a1)+			// argv[n]
nxar1:	
	tst.b	(a2)+
	bne.s	nxar1
	tst.b	(a2)
	bne.s	nxarg

// --- end of environment
xenv:
	move.l	_argvecs,d0			// if we got an argv[]
	bne.s	argok				// don't parse command tail

// --- No ARGV, parse the command tail
// NOTE: This code parses the command tail IN PLACE.  This can cause problems
//       because the default DTA set up by GEMDOS for a program is located
//       in the command tail part of the basepage.  You should use Fsetdta()
//       to set up your own DTA before performing any operations which could
//       use the DTA if you want to preserve the arguments in the command tail.

nargv:
	clr.l	(a1)+				// terminate envp[]
	move.l	a1,_argvecs			// base of argv[]
	move.l	#_argv0,(a1)+		// default name for argv[0]
	lea		128(a5),a2			// command tail
	move.b	(a2)+,d2			// length byte
	ext	d2
	moveq	#125,d1				// validate length
	cmp		d1,d2
	bcs.s	valen
	move	d1,d2				// if invalid length, copy all of tail
valen:	
	clr.b	0(a2,d2)			// null tail because desktop inserts <cr>
	moveq	#' ',d1				// space terminator
get1:	
	move.b	(a2)+,d2			// null byte?
	beq.s	argok				// if so, we're done
	cmp.b	d1,d2				// strip leading spaces
	beq.s	get1
	subq	#1,a2				// unstrip start char
	move.l	a2,(a1)+			// and store that arg
get2:	
	move.b	(a2)+,d2			// next char
	beq.s	argok				// if null, we're done
	cmp.b	d1,d2				// if not space...
	bne.s	get2				// keep looking
	clr.b	-1(a2)				// terminate argv[argc] in the command tail
	bra.s	get1				// get next arg
argok:	
	clr.l	(a1)+				// terminate argv[]

// --- allocate stack
	move.l	a1,_stklimit		// end of env/arg vectors is stack limit
	add.l	_stksize,a1			// allocate _stksize bytes of stack
	move.l	a1,sp				// set initial stack pointer

// --- release unused memory
	sub.l	a5,a1				// size to keep
	move.l	a1,-(sp)
	move.l	a5,-(sp)			// base of block to shrink
	pea		0x4a0000			// Mshrink fn code + junk word of 0
	trap	#1
	lea		12(sp),sp			// pop args

// Everything beyond here depends on implementation.
// At this point, _environ points to envp[], _argvecs points to argv[],
// and _stklimit points to the end of the argv array.  Thus argc can
// be calculated as ((_stklimit-_argvecs)/4)-1.
// _main could be invoked as follows:

//	move.l	a5,-(sp)			// basepage
//	move.l	_environ,-(sp)		// envp[]
	move.l	_argvecs,-(sp)		// argv[]
	move.l	_stklimit,d0		// 4 bytes past end of argv[]
	sub.l	(sp),d0				// (argc+1) // sizeof( char // )
	asr.l	#2,d0				// argc+1
	subq	#1,d0				// argc
	move.l	d0,-(sp)
	jsr		_main				// call mainline
//	lea		14(sp),sp			// pop args
	lea		8(sp),sp			// pop args
	move.w	#0,-(sp)			// Pterm(0)
	move.w	#76,-(sp) 
	trap	#1
