# PS2 Zig Hello World - Using Zig frontend with PS2 LLVM backend
# Build pipeline: Zig → LLVM bitcode → PS2 Clang → Object → GCC Linker → ELF

EE_BIN = test_zig.elf
EE_OBJS = crt0.o main.o

# Tools
ZIG = zig
EE_CC = clang
EE_LD = mips64r5900el-ps2-elf-gcc

# Zig: emit LLVM bitcode (generic mips64el target)
ZIG_TARGET = -target mips64el-freestanding-none
ZIG_FLAGS = $(ZIG_TARGET) -O ReleaseSmall -fno-stack-protector

# PS2 Clang: compile bitcode/C with R5900 target (uses local LLVM backend)
EE_CFLAGS = --target=mips64el-scei-ps2
EE_CFLAGS += -mabi=n32 -fno-pic -G0 -mno-gpopt
EE_CFLAGS += -D_EE -Os -ffreestanding
EE_CFLAGS += -ffunction-sections -fdata-sections
EE_CFLAGS += -I$(PS2DEV)/ee/mips64r5900el-ps2-elf/include
EE_CFLAGS += -I$(PS2SDK)/ee/include -I$(PS2SDK)/common/include

# Linker flags
EE_LDFLAGS = -nostartfiles -T linkfile
EE_LDFLAGS += -L$(PS2SDK)/ee/lib
EE_LDFLAGS += -z max-page-size=128

# Libraries
EE_LIBS = -lkernel

.PHONY: all clean run sim

all: $(EE_BIN)

# Step 1: Zig → LLVM bitcode
main.bc: main.zig
	$(ZIG) build-obj -fno-emit-bin -femit-llvm-bc=main.bc $(ZIG_FLAGS) main.zig

# Step 2: PS2 Clang compiles bitcode → object (uses local PS2 LLVM backend)
main.o: main.bc
	$(EE_CC) $(EE_CFLAGS) -c main.bc -o main.o

# crt0 compiled directly with PS2 Clang
crt0.o: crt0.c
	$(EE_CC) $(EE_CFLAGS) -c crt0.c -o crt0.o

# Final link with GCC (uses ld.lld internally)
$(EE_BIN): $(EE_OBJS)
	$(EE_LD) $(EE_LDFLAGS) -o $@ $^ $(EE_LIBS)

clean:
	rm -f $(EE_BIN) $(EE_OBJS) main.bc

# Run on real PS2 via ps2client
run: $(EE_BIN)
	ps2client -h 192.168.1.10 execee host:$(EE_BIN)

# Run in PCSX2 emulator
sim: $(EE_BIN)
	flatpak --filesystem=host run net.pcsx2.PCSX2 $(PWD)/$(EE_BIN)
