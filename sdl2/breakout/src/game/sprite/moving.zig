const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const ZgRect = ziggame.Rect;

pub const MovingSprite = struct {
    const Self = MovingSprite;
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    vel: i32,
    width: i32,
    height: i32,
    canvas: ziggame.Canvas,
    state: i32 = 0,

    pub fn destroy(self: *Self) void {
        self.canvas.texture.destroy();
    }

    pub fn update(self: *Self) void {
        if (self.state < 0) return; // termination state < 0

        if (self.state < 32) {
            self.x += self.dx * self.vel;
            self.y += self.dy * self.vel;
            self.state += 1;
        } else {
            self.state = -1;
        }
    }

    pub fn draw(self: Self, zg: *ZigGame) void {
        if (self.state < 0) return; // termination state < 0
        zg.renderer.copy(self.canvas.texture, self.position_rect(), self.size_rect()) catch return;
    }

    pub fn size_rect(self: Self) sdl.Rectangle {
        return sdl.Rectangle{
            .x = 0,
            .y = 0,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn position_rect(self: Self) sdl.Rectangle {
        return sdl.Rectangle{
            .x = self.x,
            .y = self.y,
            .width = self.width,
            .height = self.height,
        };
    }
};
