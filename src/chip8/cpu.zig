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
        const opcode: u16 = @as(u16, self.memory.data[self.pc]) << 8 | self.memory.data[self.pc + 1];
        self.pc += 2; // Move to the next instruction

        // Decode and execute the opcode
        switch (opcode & 0xF000) {
            0x0000 => {
                switch (opcode) {
                    0x00E0 => {
                        // Clear the display
                        for (0..(self.display.buffer.len)) |i| {
                            self.display.buffer[i] = false;
                        }
                        //self.display.draw();
                    },
                    else => {
                        // Handle other 0x0000 opcodes here
                        std.debug.print("Unknown opcode: {x}\n", .{opcode});
                    },
                }
            },
            0x1000 => {
                // Jump to address NNN
                self.pc = opcode & 0x0FFF;
            },
            0x6000 => {
                // Set Vx to NN
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const nn: u8 = @as(u8, @intCast(opcode & 0x00FF));
                self.v[x] = nn;
            },
            0x7000 => {
                // Add NN to Vx
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const nn: u8 = @as(u8, @intCast(opcode & 0x00FF));
                self.v[x] +%= nn;
            },
            0xA000 => {
                // Set I to NNN
                self.ir = opcode & 0x0FFF;
            },
            0xD000 => {
                // Draw sprite at coordinate (Vx, Vy) with height N
                var x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                var y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                const height: u8 = @as(u8, @intCast(opcode & 0x000F));

                x = self.v[x] & 63;
                y = self.v[y] & 31;

                var row: u8 = 0;
                while (row < height) : (row += 1) {
                    const spriteByte: u8 = self.memory.data[self.ir + row];
                    var col: u8 = 0;
                    while (col < 8) : (col += 1) {
                        const shiftedCol: u8 = @as(u8, 128) >> @intCast(col);
                        const pixel: bool = (spriteByte & shiftedCol) != 0;
                        if (pixel) {
                            const pixelX: u16 = (x + col) % 64;
                            const pixelY: u16 = (y + row) % 32;

                            if (self.display.buffer[pixelY * 64 + pixelX] == true) {
                                // Collision detected
                                self.v[0xF] = 1; // Set VF to 1
                            } else {
                                self.v[0xF] = 0; // No collision
                            }

                            self.display.buffer[pixelY * 64 + pixelX] ^= true; // Toggle pixel
                        }
                    }
                }
                //self.display.draw();
            },
            else => {
                // Handle unknown opcodes
                std.debug.print("Unknown opcode: {x}\n", .{opcode});
            },
        }

        // Update Timers
        if (self.delayTimer > 0) self.delayTimer -= 1;
        if (self.soundTimer > 0) self.soundTimer -= 1;
    }
};
