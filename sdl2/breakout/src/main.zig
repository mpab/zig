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
    GAME_OVER,
    GAME_OVER_HIGH_SCORE,
    ENTER_HIGH_SCORE,
};

const NameAndScore = struct {};

// TODO
// determine why appending to this collection fails outsid of main
// (memory ownership/transfer/scope issue? - do I need to defer?)
//const SpriteGroup = std.ArrayList(zg.sprite.Sprite);

const GameContext = struct {
    zg_ctx: zg.gfx.Context,
    level: u16,
    score: u64,
    lives: u64,
    high_score: u64,
    game_state: GameState,
    ticker: game.time.Ticker,
    bounds: zg.sdl.Rectangle,
    bricks: zg.sprite.Group,
    animations: zg.sprite.Group,
    ball: ?*zg.sprite.Sprite = null,
    bat: ?*zg.sprite.Sprite = null,
    deadly_border: ?*zg.sprite.Sprite = null,

    fn init() !GameContext {
        // NOTE: defer frees resources when going out of scope
        //defer zg.sdl.SDL_DestroyWindow(window);
        var zg_ctx = zg.gfx.Context.init(game.constant.SCREEN_WIDTH, game.constant.SCREEN_HEIGHT) catch |err| return err;

        return .{
            .zg_ctx = zg_ctx,
            .level = 0,
            .lives = 0,
            .score = 0,
            .high_score = 0,
            .game_state = GameState.ATTRACT,
            .bounds = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = zg_ctx.size.width_pixels, .height = zg_ctx.size.height_pixels },
            .bricks = zg.sprite.Group.init(),
            .animations = zg.sprite.Group.init(),
            .ticker = game.time.Ticker.init(),
            // .ball = &ball,
            // .bat = &bat,
            // .deadly_border = &deadly_border,
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
    gctx.ticker.reset();
}

fn reset_ball(gctx: *GameContext) void {
    var pos = get_screen_center(gctx);
    gctx.ball.?.x = pos.x;
    gctx.ball.?.y = pos.y;
    gctx.ball.?.ext.vx = gctx.level + 3;
    gctx.ball.?.ext.vy = gctx.level + 3;
}

// state handlers
fn run_new_game(gctx: *GameContext) !void {
    gctx.lives = 1;
    gctx.level = 1;
    gctx.score = 0;
    set_game_state(gctx, GameState.GET_READY);

    try draw_game_screen(gctx); // prevent flicker
}

fn run_attract(gctx: *GameContext) !void {
    gctx.ball.?.update();

    var point = get_screen_center(gctx);

    if ((0 <= gctx.ticker.counter_ms) and (gctx.ticker.counter_ms <= 2000)) {
        try zg.text.draw_text_centered(&gctx.zg_ctx, "Press Mouse Button", point.x, point.y, 4);
    } else if ((2000 <= gctx.ticker.counter_ms) and (gctx.ticker.counter_ms <= 4000)) {
        try zg.text.draw_text_centered(&gctx.zg_ctx, "To Start", point.x, point.y, 4);
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
    try zg.text.draw_text(&gctx.zg_ctx, string, 4, 4, 2);
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
        //var brick = &gctx.bricks.list.items[result.index];
        //brick.ext.vy = -1;
        var moving_brick = game.sprite.DisappearingMovingSprite.clone(gctx.bricks.remove(result.index));
        moving_brick.ext.vy = 1;
        try gctx.animations.add(moving_brick);

        var moving_text = try game.sprite.DisappearingMovingSprite.text(gctx.zg_ctx, "+10", moving_brick.bounds, moving_brick.x, moving_brick.y, 0, -1);
        try gctx.animations.add(moving_text);

        gctx.ball.?.ext.vy = -gctx.ball.?.ext.vy;
        gctx.score += 10;
    }

    // handle bat/ball collision
    if (zg.sprite.collide_rect(gctx.ball.?, gctx.bat.?)) {
        gctx.ball.?.ext.vy = -gctx.ball.?.ext.vy;
    }

    // handle deadly border/ball collision
    if (zg.sprite.collide_rect(gctx.ball.?, gctx.deadly_border.?)) {
        set_game_state(gctx, GameState.LIFE_LOST);
    }

    try draw_game_screen(gctx);
}

fn run_life_lost(gctx: *GameContext) !void {
    var point = get_screen_center(gctx);

    if (gctx.ticker.counter_ms <= 2000) {
        if (gctx.lives == 1) {
            try zg.text.draw_text_centered(&gctx.zg_ctx, "No Lives Left!", point.x, point.y, 4);
        } else {
            try zg.text.draw_text_centered(&gctx.zg_ctx, "You Lost a Life!", point.x, point.y, 4);
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

    try draw_game_screen(gctx);
}

fn run_get_ready(gctx: *GameContext) !void {
    reset_ball(gctx);
    gctx.ball.?.draw(gctx.zg_ctx);
    try draw_game_screen(gctx);

    if (gctx.ticker.counter_ms <= 2000) {
        var point = get_screen_center(gctx);
        try zg.text.draw_text_centered(&gctx.zg_ctx, "Get Ready!", point.x, point.y, @intCast(u8, gctx.ticker.counter));
    } else {
        reset_ball(gctx);
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
    try zg.text.draw_text_centered(&gctx.zg_ctx, "Game Over", x, y, 4);

    if (gctx.ticker.counter_ms > 2000) {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_over_high_score(gctx: *GameContext) !void {
    try draw_game_screen(gctx);

    var point = get_screen_center(gctx);
    if (gctx.ticker.counter_ms <= 2000) {
        try zg.text.draw_text_centered(&gctx.zg_ctx, "Congratulations!", point.x, point.y, 4);
    } else if (gctx.ticker.counter_ms <= 4000) {
        try zg.text.draw_text_centered(&gctx.zg_ctx, "New High Score!", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.ENTER_HIGH_SCORE);
    }
}

fn run_level_complete(gctx: *GameContext) !void {
    var point = get_screen_center(gctx);
    try zg.text.draw_text_centered(&gctx.zg_ctx, "Enter Your Name", point.x, point.y, 4);
}

fn run_enter_high_score(gctx: *GameContext) !void {
    if (gctx.ticker.counter_ms <= 2000) {
        var point = get_screen_center(gctx);
        try zg.text.draw_text_centered(&gctx.zg_ctx, "Enter Your Name", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_state(gctx: *GameContext) !bool {
    gctx.ticker.tick();

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
        .ENTER_HIGH_SCORE => {
            try run_enter_high_score(gctx);
        },
    }

    return true;
}

fn add_bricks(gctx: *GameContext) !void {
    var bounds = gctx.bounds;
    var bricks_y_offset: i32 = game.constant.BRICK_HEIGHT * 4 + gctx.level;
    for (range(game.constant.NUM_BRICK_ROWS), 0..) |_, r| {
        var canvas = try game.shape.brick(gctx.zg_ctx, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, @intCast(i32, r));
        for (range(game.constant.BRICKS_PER_COLUMN), 0..) |_, c| {
            var x = @intCast(i32, c * game.constant.BRICK_WIDTH);
            var y = bricks_y_offset + @intCast(i32, (r * game.constant.BRICK_HEIGHT));
            var brick = game.sprite.BasicSprite.new(canvas, bounds, x, y);
            try gctx.bricks.list.append(brick);
        }
    }
}

pub fn main() !void {
    var gctx = try GameContext.init();
    var zg_ctx = gctx.zg_ctx;
    var bounds = gctx.bounds;

    var ball_canvas = try game.shape.ball(zg_ctx, game.constant.BALL_RADIUS);
    gctx.ball = @constCast(&(game.sprite.BouncingSprite.new(ball_canvas, bounds, 100, 100, 2, 2)));

    var bat_canvas = try game.shape.bat(zg_ctx);
    gctx.bat = @constCast(&(game.sprite.BasicSprite.new(bat_canvas, bounds, @divTrunc(bounds.width, 2), bounds.height - 2 * game.constant.BRICK_HEIGHT)));

    var deadly_border_canvas = try game.shape.filled_rect(zg_ctx, game.constant.SCREEN_WIDTH, 4, game.color.red);
    gctx.deadly_border = @constCast(&(game.sprite.BasicSprite.new(deadly_border_canvas, bounds, 0, bounds.height - 4)));

    try add_bricks(&gctx);

    while (try run_game_state(&gctx)) {
        gctx.zg_ctx.renderer.present();
    }

    zg.system.shutdown();
}
