// v4map.prg
// softkick from TOS to AmigaOS (or another TOS)

#include <mint/mintbind.h>
#include <mint/sysvars.h>
#include <mint/osbind.h>

#define V4_ROM_DIRECT	0x00F80000
#define V4_ROM_MAPPED	0x0F800000
#define V4_EXP_DIRECT	0x00E00000
#define V4_EXP_MAPPED	0x0FE00000

#define KB256			(1024L * 256L)
#define KB512			(1024L * 512L)
#define KB1024			(1024L * 1024L)

#define FNAME_ROM		"kick.rom"

typedef signed char		int8;
typedef unsigned char	uint8;
typedef signed short	int16;
typedef unsigned short	uint16;
typedef signed int		int32;
typedef unsigned int	uint32;

int32 tosrom = 0;
const uint32 stksize = STACK_SIZE;
const char* argv0 = BUILD_BIN;
uint8 buf[KB1024];

static void memcpy(uint32* dst, uint32* src, uint32 size) {
	while (size) {
		*dst++ = *src++;
		size-=4;
	}
}

static char equal(uint32* dst, uint32* src, uint32 size) {
	while (size) {
		if (*dst++ != *src++)
			return 0;
		size-=4;
	}
	return 1;
}

static inline void SetSR(uint16 r) {
	__asm__ volatile ( "move.w %0,sr\n\r" : : "d"(r) : "cc" );
}

static inline void SetVBR(uint32 r) {
	__asm__ volatile ( "movec %0,vbr\n\r" : : "d"(r) : "cc" );
}

static inline void V4RomCtrl(uint16 r) {
	__asm__ volatile (
		"move.w	%0,0xdff3fe\n\t"
		"tst.w	0xdff002\n\t"
		: : "d"(r) : "cc"
	);	
}

static void StopEverything() {
	*((volatile uint16*)0xdff096) = 0x7FFF;		// disable dma
	*((volatile uint16*)0xdff09a) = 0x7FFF;		// disable interrupts
	*((volatile uint16*)0xdff09c) = 0x0000;		// clear pending
	*((volatile uint16*)0xdff296) = 0x7FFF;		// disable dma 2
	*((volatile uint16*)0xdff29a) = 0x7FFF;		// disable interrupts 2
	*((volatile uint16*)0xdff29c) = 0x0000;		// clear pending 2
	*((volatile uint16*)0xdff1f4) = 0;			// disable saga video
	SetSR(0x2700);								// disable autovector interrupts
	SetVBR(0);									// restore vbr
}

static void CopyRomInPlace() {
	V4RomCtrl(0xB00B);				// maprom and writeprotect off
	memcpy((uint32*)V4_EXP_MAPPED, (uint32*)buf, KB512);
	memcpy((uint32*)V4_EXP_DIRECT, (uint32*)buf, KB512);
	memcpy((uint32*)V4_ROM_MAPPED, (uint32*)(buf + KB512), KB512);
	memcpy((uint32*)V4_ROM_DIRECT, (uint32*)(buf + KB512), KB512);
	V4RomCtrl(0x0001);				// maprom and writeprotect on
}

void ExecuteAmigaRom()
{
	StopEverything();
	CopyRomInPlace();
	__asm__ volatile (
		".balign 4\n\r"
		"	nop\n\t"
		"	move.l	#0,0x4\n\t"			// kill kickstart
		"	lea.l	0x01000000,a0\n\t"
		"	sub.l	-0x14(a0),a0\n\t"
		"	move.l	4(a0),a0\n\t"
		"	subq.l	#2,a0\n\t"
		"	reset\n\t"
		"	jmp		(a0)\n\t"
		"	nop\n\t"
		"	nop\n\t"
		"	nop\n\t"
		"	nop\n\t"
	: : : "a0", "cc");
}

void ExecuteAtariRom()
{
	StopEverything();
	*((volatile uint32*)0x0) = *((uint32*)&buf[214]);
	*((volatile uint32*)0x4) = *((uint32*)&buf[218]);
	CopyRomInPlace();
	__asm__ volatile (
		".balign 4\n\r"
		"	nop\n\t"
		"	move.l	#0,0x426\n\t"		// resvalid
		"	move.l	#0,0x420\n\t"		// memvalid
		"	move.l	#0,0x5a8\n\t"		// ramvalid
		"	move.l	#0,0x6fc\n\t"		// warm_magic
		"	move.l	0x4,a0\n\r"
		"	reset\n\t"
		"	jmp		(a0)\n\t"
		"	nop\n\t"
		"	nop\n\t"
		"	nop\n\t"
		"	nop\n\t"
	: : : "a0", "cc");
}


int main(int argc, char** argv) {

	const char* fname = (argc > 1) ? argv[1] : FNAME_ROM;

	// load rom
	int32 result = Fopen(fname, 0);
	if (result < 0) {
		Cconws("Err: Failed to open rom\n\r");
		return -1;
	}
	int16 f = (int16) result;
	int32 size = Fseek(0, f, SEEK_END);
	if ((size != KB256) && (size != KB512) && (size != KB1024)) {
		Cconws("Err: Invalid rom size\n\r");
		Fclose(f);
		return -1;
	}
	Fseek(0, f, SEEK_SET);
	if (Fread(f, size, buf) != size) {
		Cconws("Err: Failed to read rom\n\r");
		Fclose(f);
		return -1;
	}
	Fclose(f);

	// atari or amiga rom?
	tosrom = (*((uint32*)&buf[258]) == 'ETOS') ? 1 : -1;

	// prevent infinite reset loop when mapping emutos through auto folder
	if (tosrom && 
		equal((uint32*)V4_ROM_MAPPED, (uint32*)buf, size) &&
		equal((uint32*)V4_ROM_DIRECT, (uint32*)buf, size)) {
		return 0;
	}

	// fill regions
	if (size < KB512) {
		memcpy((uint32*)(buf + KB256), (uint32*)buf, KB256);
	}
	if (size < KB1024) {
		memcpy((uint32*)(buf + KB512), (uint32*)buf, KB512);
	}

	Supexec(tosrom > 0 ? ExecuteAtariRom : ExecuteAmigaRom);
	__builtin_unreachable;
}

void __main() {
}
