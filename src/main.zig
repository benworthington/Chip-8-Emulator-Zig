const std = @import("std");
const rl = @import("raylib");
const Display = @import("chip8/display.zig").Display;
const Memory = @import("chip8/memory.zig").Memory;

const screenWidth = 640;
const screenHeight = 320;

const display = Display.init(screenWidth, screenHeight);

var memory = Memory.init();

pub fn main() anyerror!void {
    try memory.loadRom("ibm-logo.ch8");

    rl.initWindow(screenWidth, screenHeight, "Chip-8 Emulator");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        display.draw();
    }
}
