const std = @import("std");

const Constants = @import("constants.zig").Constants;
const Instruction = @import("instruction.zig").Instruction;
const Memory = @import("memory.zig").Memory;
const Display = @import("display.zig").Display;
const Input = @import("input.zig").Input;

pub const CPU = struct {
    pc: u16 = Constants.PROGRAM_START, // Program counter
    ir: u16 = 0, // Instruction register
    sp: u8 = 0, // Stack pointer
    stack: [Constants.STACK_DEPTH]u16 = undefined, // Stack for subroutine calls
    v: [Constants.NUM_REGISTERS]u8 = undefined, // V registers

    delayTimer: *u8, // Delay timer
    soundTimer: *u8, // Sound timer

    memory: *Memory, // Pointer to memory
    display: *Display, // Pointer to display
    input: *Input, // Pointer to input

    rng: std.Random.DefaultPrng,

    pub fn init(memory: *Memory, display: *Display, input: *Input, delayTimer: *u8, soundTimer: *u8) !CPU {
        var cpu = CPU{ .memory = memory, .display = display, .input = input, .delayTimer = delayTimer, .soundTimer = soundTimer, .rng = std.Random.DefaultPrng.init(blk: {
            var seed: u64 = undefined;
            try std.posix.getrandom(std.mem.asBytes(&seed));
            break :blk seed;
        }) };

        @memset(&cpu.stack, 0);
        @memset(&cpu.v, 0);

        return cpu;
    }

    pub fn tick(self: *CPU) void {
        // Fetch
        const opcode: u16 = @as(u16, self.memory.data[self.pc]) << 8 | self.memory.data[self.pc + 1];
        self.pc += 2;

        // Decode
        const instruction = Instruction.decode(opcode);

        // Execute
        self.execute(instruction);
    }

    fn execute(self: *CPU, instruction: Instruction) void {
        switch (instruction) {
            .NOP => {},
            .CLS => self.display.clear(),
            .RET => {
                if (self.sp > 0) {
                    self.sp -= 1;
                    self.pc = self.stack[self.sp];
                } else {
                    @panic("Stack underflow");
                }
            },
            .JP => |nnn| self.pc = nnn,
            .CALL => |nnn| {
                self.stack[self.sp] = self.pc;
                self.sp += 1;
                self.pc = nnn;
            },
            .SE_VX_NN => |data| {
                if (self.v[data.vx] == data.nn) {
                    self.pc += 2;
                }
            },
            .SNE_VX_NN => |data| {
                if (self.v[data.vx] != data.nn) self.pc += 2;
            },
            .SE_VX_VY => |data| {
                if (self.v[data.vx] == self.v[data.vy]) self.pc += 2;
            },
            .LD_VX_NN => |data| self.v[data.vx] = data.nn,
            .ADD_VX_NN => |data| self.v[data.vx] +%= data.nn,
            .LD_VX_VY => |data| self.v[data.vx] = self.v[data.vy],
            .OR_VX_VY => |data| self.v[data.vx] |= self.v[data.vy],
            .AND_VX_VY => |data| self.v[data.vx] &= self.v[data.vy],
            .XOR_VX_VY => |data| self.v[data.vx] ^= self.v[data.vy],
            .ADD_VX_VY => |data| {
                const result = self.v[data.vx] +% self.v[data.vy];
                self.v[data.vx] = @as(u8, result);
                self.v[0xF] = if (result > 0xFF) 1 else 0;
            },
            .SUB_VX_VY => |data| {
                self.v[0xF] = if (self.v[data.vx] > self.v[data.vy]) 1 else 0;
                self.v[data.vx] -%= self.v[data.vy];
            },
            .SHR_VX => |vx| {
                self.v[0xF] = self.v[vx] & 1;
                self.v[vx] >>= 1;
            },
            .SUBN_VX_VY => |data| {
                self.v[0xF] = if (self.v[data.vy] > self.v[data.vx]) 1 else 0;
                self.v[data.vx] = @as(u8, self.v[data.vy] - self.v[data.vx]);
            },
            .SHL_VX => |vx| {
                self.v[0xF] = self.v[vx] >> 7;
                self.v[vx] <<= 1;
            },
            .SNE_VX_VY => |data| {
                if (self.v[data.vx] != self.v[data.vy]) self.pc += 2;
            },
            .LD_I_NNN => |nnn| self.ir = nnn,
            .JP_V0_NNN => |nnn| self.pc = nnn + self.v[0],
            .RND_VX_NN => |data| self.v[data.vx] = self.rng.random().int(u8) & data.nn,
            .DRW_VX_VY_N => |data| {
                const x = self.v[data.vx] & (Constants.BASE_WIDTH - 1);
                const y = self.v[data.vy] & (Constants.BASE_HEIGHT - 1);

                // Reset VF (collision flag)
                self.v[0xF] = 0;

                var row: u8 = 0;
                while (row < data.n) : (row += 1) {
                    const spriteByte: u8 = self.memory.data[self.ir + row];
                    var col: u8 = 0;
                    while (col < 8) : (col += 1) {
                        const mask: u8 = @as(u8, 0x80) >> @intCast(col);
                        if ((spriteByte & mask) != 0) {
                            const pixelX: u16 = (x + col) % Constants.BASE_WIDTH;
                            const pixelY: u16 = (y + row) % Constants.BASE_HEIGHT;

                            if (self.display.getPixel(pixelX, pixelY)) {
                                // Any collision sets VF to 1
                                self.v[0xF] = 1;
                            }

                            self.display.setPixel(pixelX, pixelY, self.display.getPixel(pixelX, pixelY) ^ true);
                        }
                    }
                }
            },
            .SKP_VX => |vx| {
                if (self.input.isPressed(self.v[vx])) {
                    self.pc += 2;
                }
            },
            .SKNP_VX => |vx| {
                if (!self.input.isPressed(self.v[vx])) {
                    self.pc += 2;
                }
            },
            .LD_VX_DT => |vx| {
                self.v[vx] = self.delayTimer.*;
            },
            .LD_VX_K => |vx| {
                var found: bool = false;
                var pressed_key: u8 = 0;
                for (0..Constants.KEYPAD_SIZE) |i| {
                    if (self.input.wasPressed(i)) {
                        found = true;
                        pressed_key = @intCast(i);
                        break;
                    }
                }
                if (found) {
                    self.v[vx] = pressed_key;
                } else {
                    self.pc -= 2;
                }
            },
            .LD_DT_VX => |vx| {
                self.delayTimer.* = self.v[vx];
            },
            .LD_ST_VX => |vx| {
                self.soundTimer.* = self.v[vx];
            },
            .ADD_I_VX => |vx| {
                self.ir += self.v[vx];
            },
            .LD_F_VX => |vx| {
                self.ir = Constants.FONT_START + (self.v[vx] * 5);
            },
            .LD_B_VX => |vx| {
                const value = self.v[vx];
                self.memory.data[self.ir] = value / 100;
                self.memory.data[self.ir + 1] = (value / 10) % 10;
                self.memory.data[self.ir + 2] = value % 10;
            },
            .LD_I_VX => |vx| {
                for (0..(vx + 1)) |i| {
                    self.memory.data[self.ir + i] = self.v[i];
                    if (Constants.LEGACY_MODE) {
                        self.ir += 1;
                    }
                }
            },
            .LD_VX_I => |vx| {
                for (0..(vx + 1)) |i| {
                    self.v[i] = self.memory.data[self.ir + i];
                    if (Constants.LEGACY_MODE) {
                        self.ir += 1;
                    }
                }
            },
            .UNKNOWN => |raw| {
                std.debug.print("Unknown opcode 0x{X}\n", .{raw});
            },
        }
    }
};
