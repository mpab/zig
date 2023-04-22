const sdl = @import("sdl-wrapper");

//pub const SCREEN_COLOR = sdl.Color.rgb(249, 251, 255);
pub const SCREEN_COLOR = sdl.Color.rgba(0, 0, 64, 0);

pub const BALL_BORDER_COLOR = sdl.Color.rgb(192, 0, 0);
pub const BALL_FILL_COLOR = sdl.Color.rgb(255, 0, 0);
pub const BAT_BORDER_COLOR = sdl.Color.rgb(0, 128, 0);
pub const BAT_FILL_COLOR = sdl.Color.rgb(64, 192, 64);
pub const BRICK_FILL_COLOR = sdl.Color.rgb(128, 128, 192);

pub const silver = sdl.Color.rgb(192, 192, 192);
pub const red = sdl.Color.rgb(255, 0, 0);
pub const yellow = sdl.Color.rgb(255, 255, 0);
pub const blue = sdl.Color.rgb(0, 0, 255);
pub const magenta = sdl.Color.rgb(255, 0, 255);
pub const green = sdl.Color.rgb(0, 255, 0);
pub const cyan = sdl.Color.rgb(0, 255, 255);
pub const white = sdl.Color.rgb(255, 255, 255);
pub const orange = sdl.Color.rgb(192, 192, 0);

pub const midgreen = sdl.Color.rgb(64, 255, 64);
pub const dullgreen = sdl.Color.rgb(0, 128, 0);
pub const midblue = sdl.Color.rgb(64, 64, 255);
pub const lightblue = sdl.Color.rgb(224, 224, 255);
pub const midyellow = sdl.Color.rgb(192, 192, 0);
pub const gold = sdl.Color.rgb(255, 215, 0);

pub const default_text_color = sdl.Color.rgb(255, 255, 255);

pub const Gradient = struct { start: sdl.Color, end: sdl.Color };
pub const DualGradient = struct { start: Gradient, end: Gradient };

pub const MIDGREEN_TO_DULLGREEN_GRADIENT: Gradient = .{ .start = midgreen, .end = dullgreen };
pub const MIDBLUE_TO_LIGHTBLUE_GRADIENT: Gradient = .{ .start = midblue, .end = lightblue };
pub const RED_TO_ORANGE_GRADIENT: Gradient = .{ .start = red, .end = orange };
pub const YELLOW_TO_MIDYELLOW_GRADIENT: Gradient = .{ .start = yellow, .end = midyellow };

pub const ORANGE_TO_GOLD_GRADIENT: Gradient = .{ .start = orange, .end = gold };
pub const GOLD_TO_ORANGE_GRADIENT: Gradient = .{ .start = gold, .end = orange };
