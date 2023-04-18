const zg = @import("zig-game");

pub const Ticker = struct {
    ticks: u64,
    counter_ms: u64,

    pub fn init() Ticker {
        return .{
            .ticks = zg.time.get_ticks(),
            .counter_ms = 0,
        };
    }

    pub fn tick(self: *Ticker) void {
        var ticks_now = zg.time.get_ticks();
        var ticks_diff = ticks_now - self.ticks;
        self.counter_ms = ticks_diff;
    }

    pub fn reset(self: *Ticker) void {
        self.ticks = zg.time.get_ticks();
        self.counter_ms = 0;
    }
};
