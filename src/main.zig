const std = @import("std");
const rl = @import("raylib");

const Constants = @import("chip8/constants.zig").Constants;
const Emulator = @import("chip8/emulator.zig").Emulator;

pub fn main() anyerror!void {
    rl.initWindow(Constants.BASE_WIDTH * Constants.SCREEN_SCALE, Constants.BASE_HEIGHT * Constants.SCREEN_SCALE, "Chip-8 Emulator");
    defer rl.closeWindow();

    rl.setTargetFPS(Constants.FRAME_RATE);

    var emulator = try Emulator.init();
    try emulator.loadRom("ibm-logo.ch8");

    while (!rl.windowShouldClose()) {
        const deltaTime = rl.getFrameTime();
        const cyclesPerFrame: usize = @intFromFloat(Constants.CLOCK_SPEED * deltaTime);

        emulator.updateInput();

        for (0..cyclesPerFrame) |_| emulator.tick();

        emulator.updateTimers(deltaTime);
        emulator.render();
    }
}
