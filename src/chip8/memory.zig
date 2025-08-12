const std = @import("std");
const Constants = @import("constants.zig").Constants;

pub const Memory = struct {
    data: [Constants.RAM_SIZE]u8,

    pub fn init() Memory {
        var memory = Memory{ .data = undefined };
        @memset(&memory.data, 0);

        const fontset: [80]u8 = .{
            0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
            0x20, 0x60, 0x20, 0x20, 0x70, // 1
            0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
            0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
            0x90, 0x90, 0xF0, 0x10, 0x10, // 4
            0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
            0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
            0xF0, 0x10, 0x20, 0x40, 0x40, // 7
            0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
            0xF0, 0x90, 0xF8, 0x10, 0xF8, // 9
            0xF0, 0x90, 0xF0, 0x90, 0x90, // A
            0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
            0xF0, 0x80, 0x80, 0x80, 0xF0, // C
            0xE0, 0x90, 0x90, 0x90, 0xE0, // D
            0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
            0xF0, 0x80, 0xF0, 0x80, 0x80, // F
        };

        @memcpy(memory.data[Constants.FONT_START .. Constants.FONT_START + fontset.len], fontset[0..]);

        return memory;
    }

    pub fn loadRom(self: *Memory, romName: []const u8) !void {
        var romDir = try std.fs.cwd().openDir(Constants.ROM_FOLDER, .{});
        defer romDir.close();

        var rom = try romDir.openFile(romName, .{});
        defer rom.close();

        const romStats = try rom.stat();

        if (romStats.size > Constants.RAM_SIZE - Constants.PROGRAM_START) {
            return error.ROMTooLarge;
        }

        var fr = rom.reader();
        _ = try fr.readAll(self.data[Constants.PROGRAM_START..]);
    }
};
