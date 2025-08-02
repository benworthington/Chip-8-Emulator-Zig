const rl = @import("raylib");

const baseWidth: u8 = 64;
const baseHeight: u8 = 32;

pub const Display = struct {
    width: u16,
    height: u16,

    pub fn init(width: u16, height: u16) Display {
        return Display{
            .width = width,
            .height = height,
        };
    }

    pub fn draw(self: Display) void {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);

        var y: u8 = 0;
        while (y < baseHeight) : (y += 1) {
            var x: u8 = 0;
            while (x < baseWidth) : (x += 1) {
                // TODO: Check pixel state (on or off)
                rl.drawRectangle(x * self.width / baseWidth, y * self.height / baseHeight, self.width / baseWidth, self.height / baseHeight, .white);
            }
        }
    }
};
