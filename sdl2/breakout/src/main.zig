const std = @import("std");
const zg = @import("zig-game");

const game = @import("game/game.zig");
const range = zg.util.range;

const GameState = enum {
    NEW_GAME,
    ATTRACT,
    SHOW_HIGH_SCORES,
    RUNNING,
    LIFE_LOST,
    GET_READY,
    LEVEL_COMPLETE,
    NEXT_LEVEL,
    GAME_OVER,
    GAME_OVER_HIGH_SCORE,
    ENTER_HIGH_SCORE,
};

const NameAndScore = struct {};

const GameContext = struct {
    zg_ctx: *zg.gfx.Context,
    level: u16,
    score: u64,
    lives: u64,
    high_score: u64,
    game_state: GameState,
    state_ticker: game.time.Ticker,
    ball_speed_ticker: game.time.Ticker,
    bounds: zg.sdl.Rectangle,
    bricks: zg.sprite.Group,
    animations: zg.sprite.Group,
    ball: ?*zg.sprite.Sprite = null,
    bat: ?*zg.sprite.Sprite = null,
    deadly_border: ?*zg.sprite.Sprite = null,

    fn init(zgContext: *zg.gfx.Context) !GameContext {
        // don't need to cleanup, as the window lasts the lifetime of the program
        // defer zg.sdl.SDL_DestroyWindow(window);

        return .{
            .zg_ctx = zgContext,
            .level = 1,
            .lives = 0,
            .score = 0,
            .high_score = 0,
            .game_state = GameState.ATTRACT,
            .bounds = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = zgContext.size.width_pixels, .height = zgContext.size.height_pixels },
            .bricks = zg.sprite.Group.init(),
            .animations = zg.sprite.Group.init(),
            .state_ticker = game.time.Ticker.init(),
            .ball_speed_ticker = game.time.Ticker.init(),
        };
    }
};

fn get_screen_center(gctx: *GameContext) zg._type.Point {
    var x = @divTrunc(gctx.zg_ctx.size.width_pixels, 2);
    var y = @divTrunc(gctx.zg_ctx.size.height_pixels, 2);
    return .{ .x = x, .y = y };
}

// event handlers
fn handle_mouse_button_up(gctx: *GameContext, event: zg.sdl.Event) void {
    _ = event; // event
    if (gctx.game_state == GameState.ATTRACT) { // guard
        set_game_state(gctx, GameState.NEW_GAME); // state
    }
}

fn handle_mouse_motion(gctx: *GameContext, event: zg.sdl.Event) void {
    var batx = event.mouse_motion.x - @divTrunc(gctx.bat.?.canvas.width, 2);
    var baty = gctx.bat.?.y;
    gctx.bat.?.move_abs(batx, baty);
}

fn set_game_state(gctx: *GameContext, state: GameState) void {
    gctx.game_state = state;
    gctx.state_ticker.reset();
}

fn reset_ball(gctx: *GameContext) void {
    var pos = get_screen_center(gctx);
    gctx.ball.?.x = pos.x;
    gctx.ball.?.y = pos.y;
    gctx.ball.?.ext.vel = gctx.level + 3;
    gctx.ball.?.ext.dx = 1;
    gctx.ball.?.ext.dy = 1;
    gctx.ball_speed_ticker.reset();
}

// state handlers
fn run_new_game(gctx: *GameContext) !void {
    gctx.lives = 1;
    gctx.level = 1;
    gctx.score = 0;
    gctx.bricks.list.clearAndFree();
    try add_bricks(gctx);
    set_game_state(gctx, GameState.GET_READY);
    try draw_game_screen(gctx); // prevent flicker
}

fn run_attract(gctx: *GameContext) !void {
    gctx.ball.?.update();

    var point = get_screen_center(gctx);

    if (gctx.state_ticker.counter_ms <= 2000) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "Press Mouse Button", point.x, point.y, 4);
    } else if ((2000 <= gctx.state_ticker.counter_ms) and (gctx.state_ticker.counter_ms <= 4000)) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "To Start", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.GAME_OVER);
    }

    try draw_game_screen(gctx);
}

fn run_show_high_scores(gctx: *GameContext) !void {
    _ = gctx;
}

fn draw_level_lives_score(gctx: *GameContext) !void {
    const string = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "Level: {d} Lives: {d} Score: {d}",
        .{ gctx.level, gctx.lives, gctx.score },
    );
    try zg.text.draw_text(gctx.zg_ctx, string, 4, 4, 2);
    defer std.heap.page_allocator.free(string);
}

fn draw_game_screen(gctx: *GameContext) !void {
    gctx.ball.?.draw(gctx.zg_ctx);
    gctx.bricks.draw(gctx.zg_ctx);
    gctx.animations.draw(gctx.zg_ctx);
    gctx.bat.?.draw(gctx.zg_ctx);
    gctx.bat.?.draw(gctx.zg_ctx);
    gctx.deadly_border.?.draw(gctx.zg_ctx);
    try draw_level_lives_score(gctx);
}

fn run_game(gctx: *GameContext) !void {
    //try update_and_render(gctx, gctx.bricks.?);
    gctx.animations.update();
    gctx.ball.?.update();

    // handle brick/ball collision
    var result = gctx.bricks.collision_result(gctx.ball.?);
    if (result.collided) {
        //var brick = gctx.bricks.list.items[result.index];
        //brick.ext.vy = -1;
        var moving_brick = game.sprite.DisappearingMovingSprite.clone(gctx.bricks.remove(result.index));
        moving_brick.ext.dy = 1;
        moving_brick.ext.vel = 1;
        try gctx.animations.add(moving_brick);

        var moving_text = try game.sprite.DisappearingMovingSprite.text(gctx.zg_ctx, "+10", moving_brick.bounds, moving_brick.x, moving_brick.y, 1, 0, -1);
        try gctx.animations.add(moving_text);

        gctx.ball.?.ext.dy = -gctx.ball.?.ext.dy;
        gctx.score += 10;

        if (gctx.bricks.list.items.len == 0) {
            set_game_state(gctx, GameState.LEVEL_COMPLETE);
        }
    }

    // handle bat/ball collision
    if (zg.sprite.collide_rect(gctx.ball.?, gctx.bat.?)) {
        gctx.ball.?.ext.dy = -gctx.ball.?.ext.dy;
    }

    // handle deadly border/ball collision
    if (zg.sprite.collide_rect(gctx.ball.?, gctx.deadly_border.?)) {
        set_game_state(gctx, GameState.LIFE_LOST);
    }

    if (gctx.ball_speed_ticker.counter_ms > 20000) { // speed up the ball
        gctx.ball.?.ext.vel += 1;
        gctx.ball_speed_ticker.reset();
    }

    try draw_game_screen(gctx);
}

fn run_life_lost(gctx: *GameContext) !void {
    if (gctx.state_ticker.counter_ms <= 2000) {
        var point = get_screen_center(gctx);
        if (gctx.lives == 1) {
            try zg.text.draw_text_centered(gctx.zg_ctx, "No Lives Left!", point.x, point.y, 4);
        } else {
            try zg.text.draw_text_centered(gctx.zg_ctx, "You Lost a Life!", point.x, point.y, 4);
        }
    } else {
        gctx.lives -= 1;
        if (gctx.lives > 0) {
            set_game_state(gctx, GameState.GET_READY);
        } else {
            if (gctx.score > gctx.high_score) {
                set_game_state(gctx, GameState.GAME_OVER_HIGH_SCORE);
            } else {
                set_game_state(gctx, GameState.GAME_OVER);
            }
        }
    }
    gctx.animations.update();
    try draw_game_screen(gctx);
}

fn run_get_ready(gctx: *GameContext) !void {
    reset_ball(gctx);
    gctx.ball.?.draw(gctx.zg_ctx);
    try draw_game_screen(gctx);

    if (gctx.state_ticker.counter_ms < 2000) {
        var point = get_screen_center(gctx);
        try zg.text.draw_text_centered(gctx.zg_ctx, "Get Ready!", point.x, point.y, @intCast(u8, gctx.state_ticker.counter));
    } else {
        set_game_state(gctx, GameState.RUNNING);
    }
}

fn run_game_over(gctx: *GameContext) !void {
    gctx.ball.?.update();

    gctx.bricks.draw(gctx.zg_ctx);
    gctx.bat.?.draw(gctx.zg_ctx);
    gctx.bat.?.draw(gctx.zg_ctx);
    gctx.deadly_border.?.draw(gctx.zg_ctx);
    try draw_level_lives_score(gctx);

    var x = gctx.ball.?.x;
    var y = gctx.ball.?.y;
    try zg.text.draw_text_centered(gctx.zg_ctx, "Game Over", x, y, 4);

    if (gctx.state_ticker.counter_ms > 2000) {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_over_high_score(gctx: *GameContext) !void {
    try draw_game_screen(gctx);

    var point = get_screen_center(gctx);
    if (gctx.state_ticker.counter_ms <= 2000) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "Congratulations!", point.x, point.y, 4);
    } else if (gctx.state_ticker.counter_ms <= 4000) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "New High Score!", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.ENTER_HIGH_SCORE);
    }
}

fn run_next_level(gctx: *GameContext) !void {
    gctx.level += 1;
    set_game_state(gctx, GameState.GET_READY);
    try add_bricks(gctx);
    try draw_game_screen(gctx); // prevent flicker
}

fn run_level_complete(gctx: *GameContext) !void {
    var point = get_screen_center(gctx);
    try zg.text.draw_text_centered(gctx.zg_ctx, "Level Complete!", point.x, point.y, 3);

    if (gctx.state_ticker.counter_ms > 2000) {
        set_game_state(gctx, GameState.NEXT_LEVEL);
    }
    gctx.animations.update(); // complete any animations
    try draw_game_screen(gctx); // prevent flicker
}

fn run_enter_high_score(gctx: *GameContext) !void {
    if (gctx.state_ticker.counter_ms <= 2000) {
        var point = get_screen_center(gctx);
        try zg.text.draw_text_centered(gctx.zg_ctx, "Enter Your Name", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_state(gctx: *GameContext) !bool {
    gctx.state_ticker.tick();
    gctx.ball_speed_ticker.tick();

    while (zg.sdl.pollEvent()) |event| {
        switch (event) {
            .quit => return false,
            .mouse_motion => {
                handle_mouse_motion(gctx, event);
            },
            .mouse_button_up => {
                handle_mouse_button_up(gctx, event);
            },
            else => {},
        }
    }

    var renderer = gctx.zg_ctx.renderer;
    try renderer.setColor(game.color.SCREEN_COLOR);
    try renderer.clear();

    switch (gctx.game_state) {
        .NEW_GAME => {
            try run_new_game(gctx);
        },
        .ATTRACT => {
            try run_attract(gctx);
        },
        .SHOW_HIGH_SCORES => {
            try run_show_high_scores(gctx);
        },
        .RUNNING => {
            try run_game(gctx);
        },
        .LIFE_LOST => {
            try run_life_lost(gctx);
        },
        .GET_READY => {
            try run_get_ready(gctx);
        },
        .GAME_OVER => {
            try run_game_over(gctx);
        },
        .GAME_OVER_HIGH_SCORE => { // kludge
            try run_game_over_high_score(gctx);
        },
        .LEVEL_COMPLETE => {
            try run_level_complete(gctx);
        },
        .NEXT_LEVEL => {
            try run_next_level(gctx);
        },
        .ENTER_HIGH_SCORE => {
            try run_enter_high_score(gctx);
        },
    }

    return true;
}

fn add_bricks(gctx: *GameContext) !void {
    var bounds = gctx.bounds;

    //testing
    // var canvas = try game.shape.brick(gctx.zg_ctx, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, 0);
    // try gctx.bricks.list.append(game.sprite.BasicSprite.new(canvas, bounds, 20, 200));

    var bricks_y_offset: i32 = game.constant.BRICK_HEIGHT * (gctx.level + 5);
    var r: i32 = 0;
    while (r != game.constant.NUM_BRICK_ROWS) : (r += 1) {
        var canvas = try game.shape.brick(gctx.zg_ctx, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, r);
        var c: i32 = 0;
        while (c != game.constant.BRICKS_PER_COLUMN) : (c += 1) {
            var x = @intCast(i32, c * game.constant.BRICK_WIDTH);
            var y = bricks_y_offset + r * game.constant.BRICK_HEIGHT;
            var brick = game.sprite.BasicSprite.new(canvas, bounds, x, y);
            try gctx.bricks.list.append(brick);
        }
    }
}

pub fn main() !void {
    zg.system.init();

    var zgContext = try zg.gfx.Context.init(game.constant.SCREEN_WIDTH, game.constant.SCREEN_HEIGHT);

    //var gctx = GameContext.init(&zgContext); <- const weirdness in version 0.10.1...
    // fix: init using anon struct

    var gctx: GameContext = .{
        .zg_ctx = &zgContext,
        .level = 1,
        .lives = 0,
        .score = 0,
        .high_score = 0,
        .game_state = GameState.ATTRACT,
        .bounds = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = zgContext.size.width_pixels, .height = zgContext.size.height_pixels },
        .bricks = zg.sprite.Group.init(),
        .animations = zg.sprite.Group.init(),
        .state_ticker = game.time.Ticker.init(),
        .ball_speed_ticker = game.time.Ticker.init(),
    };

    var zg_ctx = gctx.zg_ctx;
    var bounds = gctx.bounds;
    var ball_canvas = try game.shape.ball(zg_ctx, game.constant.BALL_RADIUS);
    var ball = game.sprite.BouncingSprite.new(ball_canvas, bounds, -100, -100, 0, 0, 0);
    gctx.ball = &ball;
    var bat_canvas = try game.shape.bat(zg_ctx);
    var bat = game.sprite.BasicSprite.new(bat_canvas, bounds, @divTrunc(bounds.width, 2), bounds.height - 2 * game.constant.BRICK_HEIGHT);
    gctx.bat = &bat;
    var deadly_border_canvas = try game.shape.filled_rect(zg_ctx, game.constant.SCREEN_WIDTH, 4, game.color.red);
    var deadly_border = game.sprite.BasicSprite.new(deadly_border_canvas, bounds, 0, bounds.height - 4);
    gctx.deadly_border = &deadly_border;
    reset_ball(&gctx);

    while (try run_game_state(&gctx)) {
        gctx.zg_ctx.renderer.present();
    }

    zg.system.shutdown();
}
