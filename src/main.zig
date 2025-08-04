const std = @import("std");
const rl = @import("raylib");
const Display = @import("chip8/display.zig").Display;
const Input = @import("chip8/input.zig").Input;
const Memory = @import("chip8/memory.zig").Memory;
const CPU = @import("chip8/cpu.zig").CPU;

const screenWidth = 640 * 1.5;
const screenHeight = 320 * 1.5;

var display = Display.init(screenWidth, screenHeight);
var input = Input.init();
var memory = Memory.init();
var cpu = CPU.init(&memory, &display, &input);

pub fn main() anyerror!void {
    try memory.loadRom("pong.ch8");

    rl.initWindow(screenWidth, screenHeight, "Chip-8 Emulator");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(30); // Set our game to run at 30 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        // Update
        input.updateKeyStates();
        for (0..24) |_| { // Run 24 CPU cycles per frame for smoother emulation
            try cpu.cpuCycle();
        }
    }
}
