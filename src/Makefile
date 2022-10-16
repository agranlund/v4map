NAME = v4map

SRCS = crt0.S v4map.c
CPUFLAGS = -m68040 -O0
STACKSIZE = 4096

ATARI_GCC = m68k-atari-mint-gcc
NATIVE_GCC = gcc
NATIVE_EXT =
AMIGA_VASM = vasmm68k_mot

OUT_DIR = ./..
BIN = $(NAME).prg
APP = $(OUT_DIR)/$(BIN)

V4DUMP = $(OUT_DIR)/v4dump

STRIPX = ./stripx$(NATIVE_EXT)
STRIP = $(STRIPX) -v -f $(APP)


INCLUDE = -I.
LDFLAGS = -nodefaultlibs -nostartfiles -nostdlib

TARGET_DEF = -DBUILD_NAME="\"$(NAME)\"" -DBUILD_DATE="\"`date +%Y-%m-%d`\""
TARGET_DEF += -DVER="\"$(NAME) v.`date +%Y%m%d`\""
TARGET_DEF += -DBUILD_BIN="\"$(BIN)\""
TARGET_DEF += -DSTACK_SIZE=$(STACKSIZE)

CFLAGS = $(TARGET_DEF) -std=c99 -ffast-math \
	-fomit-frame-pointer -fno-exceptions \
	-Wno-multichar -Wno-unused-variable \
	-Wl,-Map,mapfile \
	-Wl,--traditional-format

SFLAGS =

## Rules
.PHONY: clean distclean

all: $(APP) $(V4DUMP)

define SRCS_LIST_TO_OBJS
	$(addprefix , $(addsuffix .o, $(foreach file, $(SRCS), \
	$(basename $(notdir $(file))))))
endef
OBJS = $(SRCS_LIST_TO_OBJS)

SRC_PATHS += $(sort $(foreach file, $(SRCS), $(dir $(file))))
VPATH :=
VPATH += $(addprefix :, $(subst  ,:, $(filter-out $($(subst, :, ,$(VPATH))), $(SRC_PATHS))))

$(STRIPX) : $(STRIPX).c
	$(NATIVE_GCC) $(STRIPX).c -o $(STRIPX)

$(V4DUMP) : v4dump.asm
	$(AMIGA_VASM) -Fhunkexe -o $@ -nosym "$<"

$(APP) : $(DISASM) $(STRIPX) $(OBJS)
	$(ATARI_GCC) $(CFLAGS) $(OBJS) $(LDFLAGS) -o $(APP)
	$(STRIP)

%.o : %.S
	$(ATARI_GCC) $(INCLUDE) $(CPUFLAGS) $(SFLAGS) -c $< -o $@

%.o : %.c
	$(ATARI_GCC) $(INCLUDE) $(CPUFLAGS) $(CFLAGS) -c $< -o $@

%.disasm : %.c
	$(ATARI_GCC) $(INCLUDE) $(CPUFLAGS) $(CFLAGS) -fverbose-asm -g -S $< -o $@

disasm: $(DISASM)

clean:
	@rm -f *~ *.o mapfile
	@rm -f $(STRIPX)
	@rm -f $(APP)
	@rm -f $(V4DUMP)

distclean:
	@rm -f *~ *.o mapfile *.bak *.disasm 
	@rm -f $(STRIPX)
	@rm -f .DS_Store
	@rm -f *.uaem
	@rm -f ../.DS_Store
	@rm -f ../*.uaem

