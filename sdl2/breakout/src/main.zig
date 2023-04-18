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

const NameScore = struct {
    name: [:0]const u8,
    score: u64,
    fn init(name: [*c]const u8, score: u64) NameScore {
        return .{ .name = std.mem.span(name), .score = score };
    }
};

pub const HighScores = std.ArrayList(NameScore);

const GameContext = struct {
    zg_ctx: *zg.gfx.Context,
    level: u16,
    score: u64,
    lives: u64,
    high_scores: HighScores,
    game_state: GameState,
    game_state_ticker: game.time.Ticker,
    bat_ball_debounce_ticker: game.time.Ticker,
    bounds: zg.sdl.Rectangle,
    animations: zg.sprite.Group, // falling brick, score sprite
    playfield: zg.sprite.Group,
    bricks: zg.sprite.Group,
    overlay: zg.sprite.Group, // high scores

    ball_idx: usize = 0,
    bat_idx: usize = 0,
    deadly_border_idx: usize = 0,

    // fn init(zgContext: *zg.gfx.Context) !GameContext {
    //     // don't need to cleanup, as the window lasts the lifetime of the program
    //     // defer zg.sdl.SDL_DestroyWindow(window);

    //     return .{
    //         .zg_ctx = zgContext,
    //         .level = 1,
    //         .lives = 0,
    //         .score = 0,
    //         .high_score = 0,
    //         .game_state = GameState.ATTRACT,
    //         .bounds = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = zgContext.size.width_pixels, .height = zgContext.size.height_pixels },
    //         .animations = zg.sprite.Group.init(),
    //         .playfield = zg.sprite.Group.init(),
    //         .bricks = zg.sprite.Group.init(),
    //         .overlay = zg.sprite.Group.init(),
    //         .game_state_ticker = game.time.Ticker.init(),
    //         .bat_ball_debounce_ticker = game.time.Ticker.init(),
    //     };
    // }
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
    var bat = &gctx.playfield.list.items[gctx.bat_idx];
    var batx = event.mouse_motion.x - @divTrunc(bat.canvas.width, 2);
    var baty = bat.y;
    bat.move_abs(batx, baty);
}

fn set_game_state(gctx: *GameContext, state: GameState) void {
    gctx.game_state = state;
    gctx.game_state_ticker.reset();
}

fn reset_ball(gctx: *GameContext) void {
    var pos = get_screen_center(gctx);
    var ball = &gctx.playfield.list.items[gctx.ball_idx];
    ball.x = pos.x;
    ball.y = pos.y;
    ball.ext.vel = gctx.level + 3;
    ball.ext.dx = 1;
    ball.ext.dy = 1;
}

// state handlers
fn run_new_game(gctx: *GameContext) !void {
    gctx.lives = 3;
    gctx.level = 1;
    gctx.score = 0;
    gctx.bricks.list.clearAndFree();
    try add_bricks(gctx);
    set_game_state(gctx, GameState.GET_READY);
    try draw_game_screen(gctx); // prevent flicker
}

fn run_attract(gctx: *GameContext) !void {
    gctx.playfield.update();
    gctx.overlay.update();

    var point = get_screen_center(gctx);

    if (gctx.game_state_ticker.counter_ms <= 2000) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "Press Mouse Button", point.x, point.y, 4);
    } else if ((2000 <= gctx.game_state_ticker.counter_ms) and (gctx.game_state_ticker.counter_ms <= 4000)) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "To Start", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.SHOW_HIGH_SCORES);
    }

    try draw_game_screen(gctx);
}

fn run_show_high_scores(gctx: *GameContext) !void {
    gctx.playfield.update();
    gctx.overlay.update();

    if (gctx.game_state_ticker.counter_ms >= 10000) {
        set_game_state(gctx, GameState.ATTRACT);
    }

    try draw_game_screen(gctx);
    gctx.overlay.draw(gctx.zg_ctx);
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
    gctx.playfield.draw(gctx.zg_ctx);
    gctx.bricks.draw(gctx.zg_ctx);
    gctx.animations.draw(gctx.zg_ctx);
    try draw_level_lives_score(gctx);
}

fn handle_ball_bat_collision(gctx: *GameContext) void {
    if (gctx.bat_ball_debounce_ticker.counter_ms < 100) {
        zg.util.log("debounce {}\n", .{gctx.bat_ball_debounce_ticker.counter_ms});
        return;
    }
    gctx.bat_ball_debounce_ticker.reset();
    var ball = &gctx.playfield.list.items[gctx.ball_idx];
    ball.ext.dy = -ball.ext.dy;
}

fn run_game(gctx: *GameContext) !void {
    //try update_and_render(gctx, gctx.bricks.?);
    gctx.playfield.update();
    gctx.animations.update();

    var ball = &gctx.playfield.list.items[gctx.ball_idx];
    var bat = &gctx.playfield.list.items[gctx.bat_idx];
    var deadly_border = &gctx.playfield.list.items[gctx.deadly_border_idx];

    // handle brick/ball collision
    var result = gctx.bricks.collision_result(ball);
    if (result.collided) {
        var moving_brick = game.sprite.DisappearingMovingSprite.clone(gctx.bricks.remove(result.index));
        moving_brick.ext.dy = 1;
        moving_brick.ext.vel = 1;
        try gctx.animations.add(moving_brick);

        var moving_text = try game.sprite.DisappearingMovingSprite.text(gctx.zg_ctx, "+10", moving_brick.bounds, moving_brick.x, moving_brick.y, 1, 0, -1);
        try gctx.animations.add(moving_text);

        ball.ext.dy = -ball.ext.dy;
        gctx.score += 10;

        if (gctx.bricks.list.items.len == 0) {
            set_game_state(gctx, GameState.LEVEL_COMPLETE);
        }
    }

    // handle bat/ball collision
    if (zg.sprite.collide_rect(ball, bat)) {
        handle_ball_bat_collision(gctx);
    }

    // handle deadly border/ball collision
    if (zg.sprite.collide_rect(ball, deadly_border)) {
        set_game_state(gctx, GameState.LIFE_LOST);
    }

    if (gctx.game_state_ticker.counter_ms > 20000) { // speed up the ball
        gctx.game_state_ticker.reset();
        if (ball.ext.vel < 20) { // maximum speed clamp
            ball.ext.vel += 1;
        }
    }

    try draw_game_screen(gctx);
}

fn run_life_lost(gctx: *GameContext) !void {
    if (gctx.game_state_ticker.counter_ms <= 2000) {
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
            set_game_state(gctx, GameState.GAME_OVER);
            for (gctx.high_scores.items) |name_score| {
                if (gctx.score > name_score.score) {
                    set_game_state(gctx, GameState.GAME_OVER_HIGH_SCORE);
                }
            }
        }
    }
    gctx.animations.update();
    try draw_game_screen(gctx);
}

fn run_get_ready(gctx: *GameContext) !void {
    reset_ball(gctx);
    try draw_game_screen(gctx);

    if (gctx.game_state_ticker.counter_ms < 2000) {
        var point = get_screen_center(gctx);
        var magnification: i32 = @intCast(i32, @divTrunc(gctx.game_state_ticker.counter_ms, 50));
        var size = if (magnification < 10) magnification else 20 - magnification;
        if (size > 0) {
            try zg.text.draw_text_centered(gctx.zg_ctx, "Get Ready!", point.x, point.y, @intCast(u8, size));
        }
    } else {
        set_game_state(gctx, GameState.RUNNING);
    }
}

fn run_game_over(gctx: *GameContext) !void {
    gctx.bricks.draw(gctx.zg_ctx);
    try draw_level_lives_score(gctx);

    var ball = &gctx.playfield.list.items[gctx.ball_idx];

    var x = ball.x;
    var y = ball.y;
    try zg.text.draw_text_centered(gctx.zg_ctx, "Game Over", x, y, 4);

    if (gctx.game_state_ticker.counter_ms > 2000) {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_over_high_score(gctx: *GameContext) !void {
    try draw_game_screen(gctx);

    var point = get_screen_center(gctx);
    if (gctx.game_state_ticker.counter_ms <= 2000) {
        try zg.text.draw_text_centered(gctx.zg_ctx, "Congratulations!", point.x, point.y, 4);
    } else if (gctx.game_state_ticker.counter_ms <= 4000) {
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

    if (gctx.game_state_ticker.counter_ms > 2000) {
        set_game_state(gctx, GameState.NEXT_LEVEL);
    }
    gctx.animations.update(); // complete any animations
    try draw_game_screen(gctx); // prevent flicker
}

fn run_enter_high_score(gctx: *GameContext) !void {
    if (gctx.game_state_ticker.counter_ms <= 2000) {
        var point = get_screen_center(gctx);
        try zg.text.draw_text_centered(gctx.zg_ctx, "Enter Your Name", point.x, point.y, 4);
    } else {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_state(gctx: *GameContext) !bool {
    gctx.game_state_ticker.tick();
    gctx.bat_ball_debounce_ticker.tick();

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

fn add_high_score_sprites(gctx: *GameContext) !void {
    var pos = get_screen_center(gctx);

    var title = try game.sprite.ScrollingSprite.text(gctx.zg_ctx, "Today's High Scores", gctx.bounds, pos.x, pos.y, 1, 0, -1);
    // gradient color.MIDBLUE_TO_LIGHTBLUE_GRADIENT, color.RED_TO_ORANGE_GRADIENT)
    try gctx.overlay.add(title);

    var yoff: i32 = 32;
    for (gctx.high_scores.items) |name_score| {
        var score_text = try std.fmt.allocPrint(std.heap.page_allocator, "{s}    {}", .{ name_score.name, name_score.score });
        var ns_Sprite = try game.sprite.ScrollingSprite.vartext(gctx.zg_ctx, score_text, gctx.bounds, pos.x, pos.y + yoff, 1, 0, -1);
        yoff = yoff + 16;
        try gctx.overlay.add(ns_Sprite);
    }

    // dummy_text_surface = shape.text_surface('abc   0123456789', font)
    // xpos = (constant.SCREEN_WIDTH - dummy_text_surface.get_rect().width) // 2
    // for idx, (name, score) in enumerate(high_scores):
    //     justified_name = name.ljust(3, ' ')
    //     justified_score = str(score).rjust(10, ' ')
    //     text = justified_name + '   ' + justified_score
    //     sprite = make_vertically_scrolling_text_sprite(
    //         font, text, color.ORANGE_TO_GOLD_GRADIENT, color.GOLD_TO_ORANGE_GRADIENT)
    //     sprite.move_abs(xpos, constant.SCREEN_HEIGHT + yoff * (idx + 3))
    //     group.add(sprite)
}

fn add_bricks(gctx: *GameContext) !void {
    var bounds = gctx.bounds;

    // testing
    // var canvas = try game.shape.brick(gctx.zg_ctx, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, 0);
    // try gctx.bricks.list.append(game.sprite.BasicSprite.new(canvas, bounds, 20, 200));

    var count: i32 = 0;

    var bricks_y_offset: i32 = game.constant.BRICK_HEIGHT * (gctx.level + 5);
    var r: i32 = 0;
    while (r != game.constant.NUM_BRICK_ROWS) : (r += 1) {
        var canvas = try game.shape.brick(gctx.zg_ctx, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, r);
        var c: i32 = 0;
        while (c != game.constant.BRICKS_PER_ROW) : (c += 1) {
            var x = @intCast(i32, c * game.constant.BRICK_WIDTH);
            var y = bricks_y_offset + r * game.constant.BRICK_HEIGHT;
            var brick = game.sprite.BasicSprite.new(canvas, bounds, x, y);
            try gctx.bricks.list.append(brick);
            count += 1;
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
        .high_scores = HighScores.init(std.heap.page_allocator),
        .game_state = GameState.ATTRACT,
        .bounds = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = zgContext.size.width_pixels, .height = zgContext.size.height_pixels },
        .animations = zg.sprite.Group.init(),
        .playfield = zg.sprite.Group.init(),
        .bricks = zg.sprite.Group.init(),
        .overlay = zg.sprite.Group.init(),
        .game_state_ticker = game.time.Ticker.init(),
        .bat_ball_debounce_ticker = game.time.Ticker.init(),
    };

    var zg_ctx = gctx.zg_ctx;
    var bounds = gctx.bounds;
    var ball_canvas = try game.shape.ball(zg_ctx, game.constant.BALL_RADIUS);
    var ball = game.sprite.BouncingSprite.new(ball_canvas, bounds, -100, -100, 0, 0, 0);
    try gctx.playfield.add(ball);
    gctx.ball_idx = 0;
    var bat_canvas = try game.shape.bat(zg_ctx);
    var bat = game.sprite.BasicSprite.new(bat_canvas, bounds, @divTrunc(bounds.width, 2), bounds.height - 2 * game.constant.BRICK_HEIGHT);
    try gctx.playfield.add(bat);
    gctx.bat_idx = 1;
    var bottom_border_canvas = try game.shape.filled_rect(zg_ctx, game.constant.SCREEN_WIDTH, 4, game.color.red);
    var deadly_border = game.sprite.BasicSprite.new(bottom_border_canvas, bounds, 0, bounds.height - 4);
    try gctx.playfield.add(deadly_border);
    gctx.deadly_border_idx = 2;
    reset_ball(&gctx);

    try gctx.high_scores.append(NameScore.init("AAA", 100));
    try gctx.high_scores.append(NameScore.init("BBB", 50));
    try gctx.high_scores.append(NameScore.init("CCC", 10));
    try add_high_score_sprites(&gctx);

    while (try run_game_state(&gctx)) {
        gctx.zg_ctx.renderer.present();
    }

    zg.system.shutdown();
}
