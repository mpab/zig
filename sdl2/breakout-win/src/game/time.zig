const zg = @import("zig-game");

pub const Ticker = struct {
    ticks: u64,
    resolution: u64,
    counter: u64,
    counter_ms: u64,

    const DEFAULT_RESOLUTION = 500;

    pub fn init() Ticker {
        return .{
            .ticks = zg.time.get_ticks(),
            .counter = 0,
            .counter_ms = 0,
            .resolution = DEFAULT_RESOLUTION,
        };
    }

    pub fn tick(self: *Ticker) void {
        var ticks_now = zg.time.get_ticks();
        if (ticks_now - self.ticks >= self.resolution) {
            self.ticks = ticks_now;
            self.counter_ms += self.resolution;
            self.counter += 1;
        }
    }

    pub fn reset(self: *Ticker) void {
        self.counter = 0;
        self.counter_ms = 0;
    }
};
