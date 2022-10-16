
Some tools for when your Vampire V4SA is flashed as a
permanent Atari machine but you want to have the ability
to boot into AmigaOS without reflashing the machine.


---------------------------------------------------
v4map.prg
---------------------------------------------------
 Atari maprom for Vampire V4SA.
 Soft-kick from Atari TOS into AmigaOS (or another TOS)

 Usage: v4map.prg {filename}
   Starting with no parameters is equivalent to "v4map.prg kick.rom"


---------------------------------------------------
v4dump
---------------------------------------------------
 AmigaOS tool for dumping the rom image
 Usage: v4dump {filename}
   Starting with no parameters is equivalent to "v4dump kick.rom"



---------------------------------------------------
Dumping the Apollo/Coffin/etc roms:
---------------------------------------------------
 The included v4dump tool will generate a proper rom image for you.
 Boot your AmigaOS configuration and run it from the CLI:
 "v4dump kick.rom"
 

 Other rom rippers would work fine too of course, just make sure
 to dump both the kickstart + extended roms and combine them into
 a single 1MB file. This is how you would do it using RomRipper:
  1. "RomRipper f8.rom $F80000 $80000"
     "RomRipper e0.rom $E00000 $80000"
  2. Combine into a single file
     On Mac/Linux: "cat e0.rom f8.rom > kick.rom"
     On Windows:   "copy e0.rom /B + f8.rom /B kick.rom /B"



