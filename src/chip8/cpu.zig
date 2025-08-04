const std = @import("std");
const Memory = @import("memory.zig").Memory;
const Display = @import("display.zig").Display;
const Input = @import("input.zig").Input;

pub const CPU = struct {
    pc: u16, // Program counter
    ir: u16, // Instruction register
    sp: u8, // Stack pointer
    stack: [16]u16, // Stack for subroutine calls
    v: [16]u8, // V registers

    delayTimer: u8, // Delay timer
    soundTimer: u8, // Sound timer

    display: *Display, // Pointer to display

    input: *Input, // Pointer to input

    memory: *Memory, // Pointer to memory

    pub fn init(memory: *Memory, display: *Display, input: *Input) CPU {
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
            .input = input,
            .display = display,
        };
    }

    pub fn cpuCycle(self: *CPU) !void {
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
                        self.display.draw();
                    },
                    0x00EE => {
                        // Return from subroutine
                        self.sp -= 1;
                        self.pc = self.stack[self.sp];
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
            0x2000 => {
                // Call subroutine at NNN
                self.stack[self.sp] = self.pc;
                self.sp += 1;
                self.pc = opcode & 0x0FFF;
            },
            0x3000 => {
                // Skip next instruction if Vx == NN
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const nn: u8 = @as(u8, @intCast(opcode & 0x00FF));
                if (self.v[x] == nn) {
                    self.pc += 2;
                }
            },
            0x4000 => {
                // Skip next instruction if Vx != NN
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const nn: u8 = @as(u8, @intCast(opcode & 0x00FF));
                if (self.v[x] != nn) {
                    self.pc += 2;
                }
            },
            0x5000 => {
                // Skip next instruction if Vx == Vy
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                if (self.v[x] == self.v[y]) {
                    self.pc += 2;
                }
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
            0x8000 => switch (opcode & 0x000F) {
                0x0000 => {
                    // Set Vx to Vy
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    self.v[x] = self.v[y];
                },
                0x0001 => {
                    // Set Vx to Vx OR Vy
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    self.v[x] |= self.v[y];
                },
                0x0002 => {
                    // Set Vx to Vx AND Vy
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    self.v[x] &= self.v[y];
                },
                0x0003 => {
                    // Set Vx to Vx XOR Vy
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    self.v[x] ^= self.v[y];
                },
                0x0004 => {
                    // Add Vy to Vx, set VF to 1 if carry, 0 otherwise
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    const sum: u16 = @intCast(@as(u16, self.v[x]) + @as(u16, self.v[y]));
                    self.v[0xF] = if (sum > 255) 1 else 0;
                    self.v[x] +%= self.v[y];
                },
                0x0005 => {
                    // Subtract Vy from Vx, set VF to 0 if borrow, 1 otherwise
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    self.v[0xF] = if (self.v[x] > self.v[y]) 1 else 0;
                    self.v[x] -%= self.v[y];
                },
                0x0006 => {
                    // Shift Vx right by 1, set VF to LSB before shift
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.v[0xF] = self.v[x] & 1;
                    self.v[x] >>= 1;
                },
                0x0007 => {
                    // Set Vx to Vy - Vx, set VF to 0 if borrow, 1 otherwise
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                    self.v[0xF] = if (self.v[y] > self.v[x]) 1 else 0;
                    self.v[x] = @as(u8, @intCast(self.v[y] -% self.v[x]));
                },
                0x000E => {
                    // Shift Vx left by 1, set VF to MSB before shift
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.v[0xF] = (self.v[x] & 0x80) >> 7;
                    self.v[x] <<= 1;
                },
                else => {
                    // Handle other 0x8000 opcodes
                    std.debug.print("Unknown opcode: {x}\n", .{opcode});
                },
            },
            0x9000 => {
                // Skip next instruction if Vx != Vy
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const y: u8 = @as(u8, @intCast((opcode & 0x00F0) >> 4));
                if (self.v[x] != self.v[y]) {
                    self.pc += 2;
                }
            },
            0xA000 => {
                // Set I to NNN
                self.ir = opcode & 0x0FFF;
            },
            0xB000 => {
                // Jump to address NNN + V0
                self.pc = (opcode & 0x0FFF) + @as(u16, self.v[0]);
            },
            0xC000 => {
                // Set Vx to random byte AND NN
                const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                const nn: u8 = @as(u8, @intCast(opcode & 0x00FF));

                var prng = std.Random.DefaultPrng.init(blk: {
                    var seed: u64 = undefined;
                    try std.posix.getrandom(std.mem.asBytes(&seed));
                    break :blk seed;
                });
                const rand = prng.random();

                self.v[x] = rand.int(u8) & nn;
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
                self.display.draw();
            },
            0xE000 => switch (opcode & 0x00FF) {
                0x009E => {
                    // Skip next instruction if key with value Vx is pressed
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    if (self.input.keyStates[self.v[x]]) {
                        self.pc += 2;
                    }
                },
                0x00A1 => {
                    // Skip next instruction if key with value Vx is not pressed
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    if (!self.input.keyStates[self.v[x]]) {
                        self.pc += 2;
                    }
                },
                else => {
                    // Handle other 0xE000 opcodes
                    std.debug.print("Unknown opcode: {x}\n", .{opcode});
                },
            },
            0xF000 => switch (opcode & 0x00FF) {
                0x0007 => {
                    // Set Vx to delay timer value
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.v[x] = self.delayTimer;
                },
                0x0015 => {
                    // Set delay timer to Vx
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.delayTimer = self.v[x];
                },
                0x0018 => {
                    // Set sound timer to Vx
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.soundTimer = self.v[x];
                },
                0x001E => {
                    // Add Vx to I
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.ir +%= @as(u16, self.v[x]);
                },
                0x000A => {
                    // Wait for a key press and store the value in Vx
                    var keyPressed: bool = false;
                    var i: u8 = 0;
                    while (i < self.input.keyStates.len) : (i += 1) {
                        if (self.input.keyStates[i]) {
                            self.v[i] = i;
                            keyPressed = true;
                            break;
                        }
                    }
                    if (!keyPressed) {
                        self.pc -= 2;
                    }
                },
                0x0029 => {
                    // Set I to the location of the sprite for digit Vx
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    self.ir = 0x50 + @as(u16, self.v[x]) * 5; // Each digit sprite is 5 bytes
                },
                0x0033 => {
                    if (self.ir + 2 >= self.memory.data.len) {
                        return error.MemoryOutOfBounds;
                    }

                    // Store BCD representation of Vx in memory at I, I+1, I+2
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    const value: u8 = self.v[x];
                    self.memory.data[self.ir] = value / 100;
                    self.memory.data[self.ir + 1] = (value / 10) % 10;
                    self.memory.data[self.ir + 2] = value % 10;
                },
                0x0055 => {
                    // Store V0 to Vx in memory starting at I
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    if (self.ir + x >= self.memory.data.len) {
                        return error.MemoryOutOfBounds;
                    }
                    for (0..(x + 1)) |i| {
                        self.memory.data[self.ir + i] = self.v[i];
                    }
                    //self.ir += x + 1; // Move I to the next free location
                },
                0x0065 => {
                    // Read V0 to Vx from memory starting at I
                    const x: u8 = @as(u8, @intCast((opcode & 0x0F00) >> 8));
                    for (0..(x + 1)) |i| {
                        self.v[i] = self.memory.data[self.ir + i];
                    }
                    //self.ir += x + 1; // Move I to the next free location
                },
                else => {
                    // Handle other 0xF000 opcodes
                    std.debug.print("Unknown opcode: {x}\n", .{opcode});
                },
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
