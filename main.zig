// PS2 Hello World in Zig
// Uses Zig frontend with PS2 LLVM backend (mips64el-scei-ps2)

// External C functions from PS2SDK (kernel.h)
extern fn _print(fmt: [*:0]const u8, ...) void;

// Entry point called by crt0 after system initialization
export fn main(_: c_int, _: [*][*:0]u8) c_int {
    _print("Hello from Zig on PlayStation 2!\n");

    // Simple infinite loop (standard for PS2 programs)
    while (true) {}

    return 0;
}
