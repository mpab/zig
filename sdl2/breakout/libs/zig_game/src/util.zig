// -------------------------------------------------------
// language extensions/helpers

// TODO: use a template approach for this where the returned indexed type can be specified as u8, i32, ...
// to prevent messy casting on the index
pub fn range(len: usize) []const void {
    return @as([*]void, undefined)[0..len];
}

//ex: for (range(sg.len), 0..) |_, i| {

pub const cast = struct {
    i8: i8,
    u8: u8,
    i16: i16,
    u16: u16,
    i32: i32,
    u32: u32,
    i64: i64,
    u64: u64,
    pub fn _(val: anytype) cast {
        return cast{
            .i8 = @intCast(i8, val),
            .i16 = @intCast(i16, val),
            .i32 = @intCast(i32, val),
            .i64 = @intCast(i64, val),
            .u8 = @intCast(u8, val),
            .u16 = @intCast(u16, val),
            .u32 = @intCast(u32, val),
            .u64 = @intCast(u64, val),
        };
    }
};

pub const div = struct {
    i8: i8,
    u8: u8,
    i16: i16,
    u16: u16,
    i32: i32,
    u32: u32,
    i64: i64,
    u64: u64,
    pub fn _(numerator: anytype, denominator: anytype) cast {
        return div{
            .i8 = @divTrunc(cast._(numerator).i8, cast._(denominator).i8),
            .i16 = @divTrunc(cast._(numerator).i8, cast._(denominator).i16),
            .i32 = @divTrunc(cast._(numerator).i8, cast._(denominator).i32),
            .i64 = @divTrunc(cast._(numerator).i8, cast._(denominator).i64),
            .u8 = @divTrunc(cast._(numerator).i8, cast._(denominator).u8),
            .u16 = @divTrunc(cast._(numerator).i8, cast._(denominator).u16),
            .u32 = @divTrunc(cast._(numerator).i8, cast._(denominator).u32),
            .u64 = @divTrunc(cast._(numerator).i8, cast._(denominator).u64),
        };
    }
};

pub const log = @import("std").debug.print;

// -------------------------------------------------------
