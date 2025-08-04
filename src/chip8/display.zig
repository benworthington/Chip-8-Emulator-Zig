const rl = @import("raylib");

const baseWidth: u16 = 64;
const baseHeight: u16 = 32;

pub const Display = struct {
    width: u16,
    height: u16,
    buffer: [baseWidth * baseHeight]bool,

    pub fn init(width: u16, height: u16) Display {
        var buffer: [baseWidth * baseHeight]bool = undefined;
        @memset(buffer[0..], false);

        return Display{
            .width = width,
            .height = height,
            .buffer = buffer,
        };
    }

    pub fn draw(self: Display) void {
        var y: u8 = 0;
        while (y < baseHeight) : (y += 1) {
            var x: u8 = 0;
            while (x < baseWidth) : (x += 1) {
                if (self.buffer[y * baseWidth + x]) {
                    rl.drawRectangle(x * self.width / baseWidth, y * self.height / baseHeight, self.width / baseWidth, self.height / baseHeight, .white);
                }
            }
        }
    }
};
