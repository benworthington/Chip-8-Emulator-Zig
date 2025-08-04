const rl = @import("raylib");

const KeyMap: [16]rl.KeyboardKey = .{
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
    keyStates: [16]bool,

    pub fn init() Input {
        return Input{
            .keyStates = [_]bool{false} ** 16,
        };
    }

    pub fn updateKeyStates(self: *Input) void {
        for (KeyMap, 0..) |key, index| {
            self.keyStates[index] = rl.isKeyDown(key);
        }
    }
};
