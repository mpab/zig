const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const ZgRect = ziggame.Rect;

pub const BouncingSprite = struct {
    const Self = BouncingSprite;
    x: i32,
    y: i32,
    dx: i32,
    dy: i32,
    vel: i32,
    width: i32,
    height: i32,
    canvas: ziggame.Canvas,
    bounds: sdl.Rectangle,
    sound: ziggame.mixer.Sound,
    state: i32 = 0,

    pub fn destroy(self: *Self) void {
        self.canvas.texture.destroy();
    }

    pub fn update(self: *Self) void {
        if (self.state < 0) return; // termination state < 0
        self.x += self.dx * self.vel;
        self.y += self.dy * self.vel;

        var sr = ZgRect.from_sdl_rect(self.position_rect());
        var bounds = ZgRect.from_sdl_rect(self.bounds);

        if (sr.left < bounds.left) {
            self.dx = -self.dx;
            sr.left = bounds.left;
            self.sound.play();
        }
        if (sr.right > bounds.right) {
            self.dx = -self.dx;
            sr.left = bounds.right - self.width;
            self.sound.play();
        }
        if (sr.top < bounds.top) {
            self.dy = -self.dy;
            sr.top = bounds.top;
            self.sound.play();
        }
        if (sr.bottom > bounds.bottom) {
            self.dy = -self.dy;
            sr.top = bounds.bottom - self.height;
            self.sound.play();
        }

        self.x = sr.left;
        self.y = sr.top;
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
