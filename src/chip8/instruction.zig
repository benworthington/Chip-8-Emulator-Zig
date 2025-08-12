pub const Instruction = union(enum) {
    // No operation / system instructions
    NOP,
    CLS, // 00E0 - Clear screen
    RET, // 00EE - Return from subroutine

    // Jump and call
    JP: u12, // 1NNN
    CALL: u12, // 2NNN
    SE_VX_NN: struct { vx: u4, nn: u8 }, // 3XNN
    SNE_VX_NN: struct { vx: u4, nn: u8 }, // 4XNN
    SE_VX_VY: struct { vx: u4, vy: u4 }, // 5XY0

    // Loads
    LD_VX_NN: struct { vx: u4, nn: u8 }, // 6XNN
    ADD_VX_NN: struct { vx: u4, nn: u8 }, // 7XNN
    LD_VX_VY: struct { vx: u4, vy: u4 }, // 8XY0
    OR_VX_VY: struct { vx: u4, vy: u4 }, // 8XY1
    AND_VX_VY: struct { vx: u4, vy: u4 }, // 8XY2
    XOR_VX_VY: struct { vx: u4, vy: u4 }, // 8XY3
    ADD_VX_VY: struct { vx: u4, vy: u4 }, // 8XY4
    SUB_VX_VY: struct { vx: u4, vy: u4 }, // 8XY5
    SHR_VX: u4, // 8XY6
    SUBN_VX_VY: struct { vx: u4, vy: u4 }, // 8XY7
    SHL_VX: u4, // 8XYE

    // Skip if not equal
    SNE_VX_VY: struct { vx: u4, vy: u4 }, // 9XY0

    // Index register
    LD_I_NNN: u12, // ANNN
    JP_V0_NNN: u12, // BNNN
    RND_VX_NN: struct { vx: u4, nn: u8 }, // CXNN

    // Drawing
    DRW_VX_VY_N: struct { vx: u4, vy: u4, n: u4 }, // DXYN

    // Input
    SKP_VX: u4, // EX9E
    SKNP_VX: u4, // EXA1

    // Timers and registers
    LD_VX_DT: u4, // FX07
    LD_VX_K: u4, // FX0A
    LD_DT_VX: u4, // FX15
    LD_ST_VX: u4, // FX18
    ADD_I_VX: u4, // FX1E
    LD_F_VX: u4, // FX29
    LD_B_VX: u4, // FX33
    LD_I_VX: u4, // FX55
    LD_VX_I: u4, // FX65

    // Fallback
    UNKNOWN: u16, // Unknown opcode (stores raw)

    pub fn decode(opcode: u16) Instruction {
        const nnn: u12 = @truncate(opcode & 0x0FFF);
        const nn: u8 = @truncate(opcode & 0x00FF);
        const n: u4 = @truncate(opcode & 0x000F);
        const x: u4 = @truncate((opcode >> 8) & 0x0F);
        const y: u4 = @truncate((opcode >> 4) & 0x0F);

        return switch (opcode & 0xF000) {
            0x0000 => switch (opcode) {
                0x00E0 => .CLS,
                0x00EE => .RET,
                else => .NOP,
            },
            0x1000 => Instruction{ .JP = nnn },
            0x2000 => Instruction{ .CALL = nnn },
            0x3000 => Instruction{ .SE_VX_NN = .{ .vx = x, .nn = nn } },
            0x4000 => Instruction{ .SNE_VX_NN = .{ .vx = x, .nn = nn } },
            0x5000 => if (n == 0) Instruction{ .SE_VX_VY = .{ .vx = x, .vy = y } } else Instruction{ .UNKNOWN = opcode },
            0x6000 => Instruction{ .LD_VX_NN = .{ .vx = x, .nn = nn } },
            0x7000 => Instruction{ .ADD_VX_NN = .{ .vx = x, .nn = nn } },
            0x8000 => switch (n) {
                0x0 => Instruction{ .LD_VX_VY = .{ .vx = x, .vy = y } },
                0x1 => Instruction{ .OR_VX_VY = .{ .vx = x, .vy = y } },
                0x2 => Instruction{ .AND_VX_VY = .{ .vx = x, .vy = y } },
                0x3 => Instruction{ .XOR_VX_VY = .{ .vx = x, .vy = y } },
                0x4 => Instruction{ .ADD_VX_VY = .{ .vx = x, .vy = y } },
                0x5 => Instruction{ .SUB_VX_VY = .{ .vx = x, .vy = y } },
                0x6 => Instruction{ .SHR_VX = x },
                0x7 => Instruction{ .SUBN_VX_VY = .{ .vx = x, .vy = y } },
                0xE => Instruction{ .SHL_VX = x },
                else => Instruction{ .UNKNOWN = opcode },
            },
            0x9000 => if (n == 0) Instruction{ .SNE_VX_VY = .{ .vx = x, .vy = y } } else Instruction{ .UNKNOWN = opcode },
            0xA000 => Instruction{ .LD_I_NNN = nnn },
            0xB000 => Instruction{ .JP_V0_NNN = nnn },
            0xC000 => Instruction{ .RND_VX_NN = .{ .vx = x, .nn = nn } },
            0xD000 => Instruction{ .DRW_VX_VY_N = .{ .vx = x, .vy = y, .n = n } },
            0xE000 => switch (nn) {
                0x9E => Instruction{ .SKP_VX = x },
                0xA1 => Instruction{ .SKNP_VX = x },
                else => Instruction{ .UNKNOWN = opcode },
            },
            0xF000 => switch (nn) {
                0x07 => Instruction{ .LD_VX_DT = x },
                0x0A => Instruction{ .LD_VX_K = x },
                0x15 => Instruction{ .LD_DT_VX = x },
                0x18 => Instruction{ .LD_ST_VX = x },
                0x1E => Instruction{ .ADD_I_VX = x },
                0x29 => Instruction{ .LD_F_VX = x },
                0x33 => Instruction{ .LD_B_VX = x },
                0x55 => Instruction{ .LD_I_VX = x },
                0x65 => Instruction{ .LD_VX_I = x },
                else => Instruction{ .UNKNOWN = opcode },
            },
            else => Instruction{ .UNKNOWN = opcode },
        };
    }
};
