const std = @import("std");
const zg = @import("zig-game");

const game = @import("game/game.zig");
const range = zg.util.range;

const TEXT_SCALING: u8 = 3; // hack for now

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

const InputEvent = struct {
    const Event = union {
        event: zg.sdl.Event,
        empty: void,
    };
    val: Event = .{ .empty = {} },
    is_empty: bool = true,

    fn init(event: zg.sdl.Event) InputEvent {
        return .{
            .is_empty = false,
            .val = .{ .event = event },
        };
    }
};

const InputEvents = struct {
    ie_mouse_motion: InputEvent = .{},
    ie_mouse_button_up: InputEvent = .{},
    ie_key_down: InputEvent = .{},
};

const NameScore = struct {
    const MAX_NAME_LEN = 3;
    name: [MAX_NAME_LEN:0]u8 = "123".*,
    score: u64,
    fn init(name: []const u8, score: u64) NameScore {
        var ns = NameScore{ .score = score };
        ns.set_name(name);
        return ns;
    }

    fn set_name(self: *NameScore, string: []const u8) void {
        var idx: usize = 0;
        while (idx != string.len) : (idx += 1) {
            if (idx < MAX_NAME_LEN) {
                self.name[idx] = string[idx];
            }
        }
    }
};

pub const NameScores = std.ArrayList(NameScore);
const PLAYER_SCORE_IDX = 3;

const GameContext = struct {
    zg_ctx: *zg.gfx.Context,
    level: u16 = 0,
    lives: u64 = 0,
    scores: NameScores = NameScores.init(std.heap.page_allocator),
    player_score_edit_pos: usize = 0,
    game_state: GameState = GameState.GAME_OVER,
    game_state_ticker: game.time.Ticker,
    bat_ball_debounce_ticker: game.time.Ticker,
    bounds: zg.sdl.Rectangle,
    animations: zg.sprite.Group = .{}, // falling brick, score sprite
    playfield: zg.sprite.Group = .{},
    bricks: zg.sprite.Group = .{},
    overlay: zg.sprite.Group = .{}, // high scores

    ball_idx: usize = 0,
    bat_idx: usize = 0,
    deadly_border_idx: usize = 0,

    input: InputEvents = .{},

    pub fn configure(zg_ctx: *zg.gfx.Context) !GameContext {
        var gctx: GameContext = .{
            .zg_ctx = zg_ctx,
            .bounds = zg.sdl.Rectangle{ .x = 0, .y = 0, .width = zg_ctx.size.width_pixels, .height = zg_ctx.size.height_pixels },
            .game_state_ticker = game.time.Ticker.init(),
            .bat_ball_debounce_ticker = game.time.Ticker.init(),
        };

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

        // 1st 3 are the high scores, the last is the current player score
        try gctx.scores.append(NameScore.init("AAA", 1000));
        try gctx.scores.append(NameScore.init("BBB", 100));
        try gctx.scores.append(NameScore.init("CCC", 10));
        try gctx.scores.append(NameScore.init("   ", 70)); // current score, 70 is for testing
        try replace_high_scores(&gctx);

        return gctx;
    }
};

fn get_screen_center(gctx: *GameContext) zg._type.Point {
    var x = @divTrunc(gctx.zg_ctx.size.width_pixels, 2);
    var y = @divTrunc(gctx.zg_ctx.size.height_pixels, 2);
    return .{ .x = x, .y = y };
}

// // event handlers
fn change_game_state_if_mouse_button_up(gctx: *GameContext, new_state: GameState) void {
    if (gctx.input.ie_mouse_button_up.is_empty) {
        return;
    }
    set_game_state(gctx, new_state); // state
}

fn handle_mouse_motion(gctx: *GameContext) void {
    if (gctx.input.ie_mouse_motion.is_empty) {
        return;
    }

    var bat = &gctx.playfield.list.items[gctx.bat_idx];
    var batx = gctx.input.ie_mouse_motion.val.event.mouse_motion.x - @divTrunc(bat.canvas.width, 2);
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
    var player_ns = &gctx.scores.items[PLAYER_SCORE_IDX];
    player_ns.score = 0;
    player_ns.set_name("   ");
    gctx.player_score_edit_pos = 0;
    try replace_bricks(gctx);
    try draw_game_screen(gctx); // prevent flicker

    set_game_state(gctx, GameState.GET_READY);
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

    change_game_state_if_mouse_button_up(gctx, GameState.NEW_GAME);
}

fn run_show_high_scores(gctx: *GameContext) !void {
    gctx.playfield.update();
    gctx.overlay.update();

    if (gctx.game_state_ticker.counter_ms >= 10000) {
        set_game_state(gctx, GameState.ATTRACT);
    }

    try draw_game_screen(gctx);
    gctx.overlay.draw(gctx.zg_ctx);

    change_game_state_if_mouse_button_up(gctx, GameState.NEW_GAME);
}

fn draw_level_lives_score(gctx: *GameContext) !void {
    var player_ns = &gctx.scores.items[PLAYER_SCORE_IDX];
    const string = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "Level: {d} Lives: {d} Score: {d}",
        .{ gctx.level, gctx.lives, player_ns.score },
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
        // zg.util.log("debounce {}\n", .{gctx.bat_ball_debounce_ticker.counter_ms});
        return;
    }
    gctx.bat_ball_debounce_ticker.reset();
    var ball = &gctx.playfield.list.items[gctx.ball_idx];
    ball.ext.dy = -ball.ext.dy;
}

fn run_game(gctx: *GameContext) !void {
    handle_mouse_motion(gctx);

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
        var player_ns = &gctx.scores.items[PLAYER_SCORE_IDX];
        player_ns.score += 10;

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
            var player_ns = &gctx.scores.items[PLAYER_SCORE_IDX];
            var idx: usize = 0;
            for (gctx.scores.items) |ns| {
                if ((idx < PLAYER_SCORE_IDX) and player_ns.score > ns.score) {
                    set_game_state(gctx, GameState.GAME_OVER_HIGH_SCORE);
                }
                idx += 1;
            }
        }
    }
    gctx.animations.update();
    try draw_game_screen(gctx);
}

fn run_get_ready(gctx: *GameContext) !void {
    handle_mouse_motion(gctx);
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

    if (gctx.game_state_ticker.counter_ms < 2000) {
        var point = get_screen_center(gctx);
        var magnification: i32 = @intCast(i32, @divTrunc(gctx.game_state_ticker.counter_ms, 50));
        var size = if (magnification < 10) magnification else 20 - magnification;
        if (size > 0) {
            try zg.text.draw_text_centered(gctx.zg_ctx, "Game Over", point.x, point.y, @intCast(u8, size));
        }
    } else {
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
    try replace_bricks(gctx);
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

fn compareNameScoresAscending(context: void, a: NameScore, b: NameScore) bool {
    _ = context;
    if (a.score > b.score) {
        return true;
    } else {
        return false;
    }
}

fn run_enter_high_score(gctx: *GameContext) !void {
    var player_ns = &gctx.scores.items[PLAYER_SCORE_IDX];
    var player_name = &player_ns.name;

    var scaled_char_wh: i32 = 8 * TEXT_SCALING;

    var point = get_screen_center(gctx);
    try zg.text.draw_text_centered(gctx.zg_ctx, "Enter Your Name", point.x, point.y, TEXT_SCALING + 1);

    var char: u8 = 0;

    // TODO: handle shift modifier
    if (!gctx.input.ie_key_down.is_empty) { // handle keypresses
        //gctx.input.ie_key_down.ve.event.key_down.
        var key = gctx.input.ie_key_down.val.event.key_down;
        var scancode = key.scancode;
        var keycode = key.keycode;
        char = @intCast(u8, @enumToInt(keycode));

        if (scancode == zg.sdl.Scancode.@"return") {
            std.sort.sort(NameScore, gctx.scores.items, {}, compareNameScoresAscending);
            try replace_high_scores(gctx);
            set_game_state(gctx, GameState.SHOW_HIGH_SCORES);
            return;
        }

        if (gctx.player_score_edit_pos > 0) {
            if (scancode == zg.sdl.Scancode.backspace) {
                gctx.player_score_edit_pos -= 1;
                player_name[gctx.player_score_edit_pos] = ' ';
            }
        }

        if (gctx.player_score_edit_pos < NameScore.MAX_NAME_LEN) {
            if (char >= 32 and char <= 127) {
                player_name[gctx.player_score_edit_pos] = char;
                gctx.player_score_edit_pos += 1;
            }
        }
        // zg.util.log("scancode {}\n", .{scancode});
        // zg.util.log("keycode {}\n", .{keycode});
        // zg.util.log("keycode value {}\n", .{char});
        // zg.util.log("--------\n", .{});
    }

    var blink_on: bool = ((gctx.game_state_ticker.counter_ms / 500) & 1) == 1;
    var text_x = point.x - ((scaled_char_wh * NameScore.MAX_NAME_LEN) >> 1);
    try zg.text.draw_text(gctx.zg_ctx, player_name, text_x, point.y + scaled_char_wh * 4, TEXT_SCALING);

    if (blink_on) {
        var cursor_x = text_x + @intCast(i32, gctx.player_score_edit_pos) * scaled_char_wh;
        try zg.text.draw_text(gctx.zg_ctx, "_", cursor_x, point.y + scaled_char_wh * 4, TEXT_SCALING);
    }
}

fn run_game_state(gctx: *GameContext) !bool {
    gctx.game_state_ticker.tick();
    gctx.bat_ball_debounce_ticker.tick();

    gctx.input = .{}; // clear last events

    while (zg.sdl.pollEvent()) |event| {
        switch (event) {
            .quit => return false,
            .mouse_motion => {
                gctx.input.ie_mouse_motion = InputEvent.init(event);
            },
            .mouse_button_up => {
                gctx.input.ie_mouse_button_up = InputEvent.init(event);
            },
            .key_down => {
                gctx.input.ie_key_down = InputEvent.init(event);
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

fn replace_high_scores(gctx: *GameContext) !void {
    // TODO: text justification
    gctx.overlay.list.clearAndFree();
    var pos = get_screen_center(gctx);
    var title = try game.sprite.ScrollingSprite.text(gctx.zg_ctx, "High Scores", gctx.bounds, pos.x, pos.y, 1, 0, -1);
    // gradient color.MIDBLUE_TO_LIGHTBLUE_GRADIENT, color.RED_TO_ORANGE_GRADIENT)
    try gctx.overlay.add(title);

    var scaled_char_wh: i32 = 8 * TEXT_SCALING;

    var yoff: i32 = scaled_char_wh * 2;
    var idx: usize = 0;
    for (gctx.scores.items) |_| {
        if (idx < PLAYER_SCORE_IDX) {
            //var score_text = try std.fmt.allocPrint(std.heap.page_allocator, "{s}    {}", .{ ns.name, ns.score });
            var name_sprite = try game.sprite.ScrollingSprite.text(gctx.zg_ctx, &gctx.scores.items[idx].name, gctx.bounds, pos.x - scaled_char_wh * 5, pos.y + yoff, 1, 0, -1);
            try gctx.overlay.add(name_sprite);

            var score_text = try std.fmt.allocPrint(std.heap.page_allocator, "{}", .{gctx.scores.items[idx].score});
            var score_max_chars: i32 = 9;
            var score_text_len = @intCast(i32, score_text.len);
            var rhs = score_max_chars - score_text_len;
            var score_x = pos.x + 16 * scaled_char_wh + (scaled_char_wh * rhs) >> 1; // magic numbers because text centering is on by default
            zg.util.log("{}, {}, {}: {}\n", .{ score_max_chars, score_text_len, rhs, score_x });
            var score_sprite = try game.sprite.ScrollingSprite.vartext(gctx.zg_ctx, score_text, gctx.bounds, score_x, pos.y + yoff, 1, 0, -1);
            try gctx.overlay.add(score_sprite);
            yoff = yoff + scaled_char_wh;
        }
        idx += 1;
    }
}

fn replace_bricks(gctx: *GameContext) !void {
    gctx.bricks.list.clearAndFree();
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
    var gctx = try GameContext.configure(&zgContext);

    //set_game_state(&gctx, GameState.ENTER_HIGH_SCORE);
    reset_ball(&gctx);

    while (try run_game_state(&gctx)) {
        gctx.zg_ctx.renderer.present();
    }

    zg.system.shutdown();
}
