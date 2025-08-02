const std = @import("std");
const Memory = @import("memory.zig").Memory;
const Display = @import("display.zig").Display;

pub const CPU = struct {
    pc: u16, // Program counter
    ir: u16, // Instruction register
    sp: u8, // Stack pointer
    stack: [16]u16, // Stack for subroutine calls
    v: [16]u8, // V registers

    delayTimer: u8, // Delay timer
    soundTimer: u8, // Sound timer

    display: *Display, // Pointer to display

    memory: *Memory, // Pointer to memory

    pub fn init(memory: *Memory, display: *Display) CPU {
        var v: [16]u8 = undefined;
        @memset(v[0..], 0);

        var stack: [16]u16 = undefined;
        @memset(stack[0..], 0);

        return CPU{
            .pc = 0x200,
            .ir = 0,
            .sp = 0,
            .stack = stack,
            .v = v,
            .delayTimer = 0,
            .soundTimer = 0,
            .memory = memory,
            .display = display,
        };
    }

    pub fn cpuCycle(self: *CPU) void {
        const opcode: u16 = self.memory.data[self.pc] << 8 | self.memory.data[self.pc + 1];
        self.pc += 2; // Move to the next instruction

        // Decode and execute the opcode
        switch (opcode & 0xF000) {}

        // Update Timers
        if (self.delayTimer > 0) self.delayTimer -= 1;
        if (self.soundTimer > 0) self.soundTimer -= 1;
    }
};
