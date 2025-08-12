const std = @import("std");
const Constants = @import("constants.zig").Constants;
const CPU = @import("cpu.zig").CPU;
const Memory = @import("memory.zig").Memory;
const Display = @import("display.zig").Display;
const Input = @import("input.zig").Input;

pub const Emulator = struct {
    memory: Memory,
    cpu: CPU,
    display: Display,
    input: Input,

    delayTimer: u8 = 0,
    soundTimer: u8 = 0,
    timerAccumulator: f32 = 0.0,

    pub fn init() !Emulator {
        var emu = Emulator{
            .memory = Memory.init(),
            .display = Display.init(),
            .input = Input.init(),
            .cpu = undefined,
        };
        emu.cpu = try CPU.init(&emu.memory, &emu.display, &emu.input, &emu.delayTimer, &emu.soundTimer);
        return emu;
    }

    pub fn loadRom(self: *Emulator, romName: []const u8) !void {
        try self.memory.loadRom(romName);
    }

    pub fn updateInput(self: *Emulator) void {
        self.input.update();
    }

    pub fn tick(self: *Emulator) void {
        self.cpu.tick();
    }

    pub fn updateTimers(self: *Emulator, deltaTime: f32) void {
        self.timerAccumulator += deltaTime;
        const tickTime: f32 = 1.0 / @as(f32, @floatFromInt(Constants.TIMER_SPEED));

        while (self.timerAccumulator >= tickTime) : (self.timerAccumulator -= tickTime) {
            if (self.delayTimer > 0) self.delayTimer -= 1;
            if (self.soundTimer > 0) self.soundTimer -= 1;
        }
    }

    pub fn render(self: *Emulator) void {
        self.display.render();
    }
};
