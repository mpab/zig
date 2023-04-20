const sdl = @import("sdl-wrapper");

//pub const SCREEN_COLOR = sdl.Color.rgb(249, 251, 255);
pub const SCREEN_COLOR = sdl.Color.rgb(0, 0, 64);

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
pub const white = sdl.Color.rgb(255, 255, 255);

pub const Gradient = struct { start: sdl.Color, end: sdl.Color };
