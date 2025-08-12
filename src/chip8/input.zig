const rl = @import("raylib");
const Constants = @import("constants.zig").Constants;

const KeyMap: [Constants.KEYPAD_SIZE]rl.KeyboardKey = .{
    rl.KeyboardKey.x,
    rl.KeyboardKey.one,
    rl.KeyboardKey.two,
    rl.KeyboardKey.three,
    rl.KeyboardKey.q,
    rl.KeyboardKey.w,
    rl.KeyboardKey.e,
    rl.KeyboardKey.a,
    rl.KeyboardKey.s,
    rl.KeyboardKey.d,
    rl.KeyboardKey.z,
    rl.KeyboardKey.c,
    rl.KeyboardKey.four,
    rl.KeyboardKey.r,
    rl.KeyboardKey.f,
    rl.KeyboardKey.v,
};

pub const Input = struct {
    keyStates: [Constants.KEYPAD_SIZE]bool,

    pub fn init() Input {
        var input = Input{ .keyStates = undefined };
        @memset(&input.keyStates, false);
        return input;
    }

    pub fn update(self: *Input) void {
        for (KeyMap, 0..) |key, index| {
            self.keyStates[index] = rl.isKeyDown(key);
        }
    }

    pub fn isPressed(self: *const Input, keyIndex: usize) bool {
        return if (keyIndex < Constants.KEYPAD_SIZE) self.keyStates[keyIndex] else false;
    }

    pub fn wasPressed(_: *const Input, keyIndex: usize) bool {
        return if (keyIndex < Constants.KEYPAD_SIZE) rl.isKeyPressed(KeyMap[keyIndex]) else false;
    }

    pub fn wasReleased(_: *const Input, keyIndex: usize) bool {
        return if (keyIndex < Constants.KEYPAD_SIZE) rl.isKeyReleased(KeyMap[keyIndex]) else false;
    }
};
