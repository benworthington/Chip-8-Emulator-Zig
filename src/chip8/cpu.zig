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
            .OR_VX_VY => |data| {
                self.v[data.vx] |= self.v[data.vy];
                if (Constants.VF_RESET_TOGGLE) {
                    self.v[0xF] = 0; // Reset VF if toggled
                }
            },
            .AND_VX_VY => |data| {
                self.v[data.vx] &= self.v[data.vy];
                if (Constants.VF_RESET_TOGGLE) {
                    self.v[0xF] = 0; // Reset VF if toggled
                }
            },
            .XOR_VX_VY => |data| {
                self.v[data.vx] ^= self.v[data.vy];
                if (Constants.VF_RESET_TOGGLE) {
                    self.v[0xF] = 0; // Reset VF if toggled
                }
            },
            .ADD_VX_VY => |data| {
                const sum: u9 = @as(u9, self.v[data.vx]) + @as(u9, self.v[data.vy]);
                self.v[data.vx] = @truncate(sum);
                self.v[0xF] = if (sum > 0xFF) 1 else 0;
            },
            .SUB_VX_VY => |data| {
                const noBorrow: u1 = if (self.v[data.vx] >= self.v[data.vy]) 1 else 0;
                self.v[data.vx] -%= self.v[data.vy];
                self.v[0xF] = noBorrow;
            },
            .SHR_VX => |data| {
                if (Constants.SHIFTING_TOGGLE) {
                    // Modern: shift vX directly
                    const original = self.v[data.vx];
                    self.v[data.vx] = original >> 0x1;
                    self.v[0xF] = original & 0x1;
                } else {
                    // Original: copy vY into vX first, then shift
                    const original = self.v[data.vy];
                    self.v[data.vx] = original >> 0x1;
                    self.v[0xF] = original & 0x1;
                }
            },
            .SUBN_VX_VY => |data| {
                const noBorrow: u1 = if (self.v[data.vy] >= self.v[data.vx]) 1 else 0;
                self.v[data.vx] = self.v[data.vy] -% self.v[data.vx];
                self.v[0xF] = noBorrow;
            },
            .SHL_VX => |data| {
                if (Constants.SHIFTING_TOGGLE) {
                    // Modern: shift vX directly
                    const original = self.v[data.vx];
                    self.v[data.vx] = original << 0x1;
                    self.v[0xF] = original >> 7;
                } else {
                    // Original: copy vY into vX first, then shift
                    const original = self.v[data.vy];
                    self.v[data.vx] = original << 0x1;
                    self.v[0xF] = original >> 7;
                }
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
                            var pixelX: u16 = x + col;
                            var pixelY: u16 = y + row;

                            if (!Constants.CLIPPING_TOGGLE) {
                                // Wrap mode
                                pixelX = @intCast((@as(u16, @intCast(pixelX)) % Constants.BASE_WIDTH));
                                pixelY = @intCast((@as(u16, @intCast(pixelY)) % Constants.BASE_HEIGHT));
                            } else {
                                // Clip mode — skip if outside
                                if (pixelX < 0 or pixelX >= Constants.BASE_WIDTH or
                                    pixelY < 0 or pixelY >= Constants.BASE_HEIGHT)
                                {
                                    continue;
                                }
                            }

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
                    if (self.input.wasReleased(i)) {
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
                const n: usize = @as(usize, vx) + 1;
                for (0..n) |i| {
                    self.memory.data[self.ir + i] = self.v[i];
                }
                if (Constants.MEMORY_TOGGLE) {
                    self.ir += @intCast(n);
                }
            },
            .LD_VX_I => |vx| {
                const n: usize = @as(usize, vx) + 1;
                for (0..n) |i| {
                    self.v[i] = self.memory.data[self.ir + i];
                }
                if (Constants.MEMORY_TOGGLE) {
                    self.ir += @intCast(n);
                }
            },
            .UNKNOWN => |raw| {
                std.debug.print("Unknown opcode 0x{X}\n", .{raw});
            },
        }
    }
};
