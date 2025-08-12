const rl = @import("raylib");
const Constants = @import("constants.zig").Constants;

pub const Display = struct {
    buffer: [Constants.BASE_WIDTH * Constants.BASE_HEIGHT]bool,

    pub fn init() Display {
        var display = Display{ .buffer = undefined };
        @memset(&display.buffer, false);
        return display;
    }

    pub fn clear(self: *Display) void {
        @memset(&self.buffer, false);
    }

    pub fn setPixel(self: *Display, x: usize, y: usize, value: bool) void {
        if (x < Constants.BASE_WIDTH and y < Constants.BASE_HEIGHT) {
            self.buffer[y * Constants.BASE_WIDTH + x] = value;
        }
    }

    pub fn getPixel(self: *const Display, x: usize, y: usize) bool {
        if (x < Constants.BASE_WIDTH and y < Constants.BASE_HEIGHT) {
            return self.buffer[y * Constants.BASE_WIDTH + x];
        }
        return false;
    }

    pub fn render(self: *const Display) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        for (0..Constants.BASE_HEIGHT) |y| {
            for (0..Constants.BASE_WIDTH) |x| {
                if (self.getPixel(x, y)) {
                    rl.drawRectangle(@intCast(x * Constants.SCREEN_SCALE), @intCast(y * Constants.SCREEN_SCALE), Constants.SCREEN_SCALE, Constants.SCREEN_SCALE, .white);
                }
            }
        }
    }
};
