const std = @import("std");
const dbg = std.log.debug;
const ziggame = @import("zig-game"); // namespace
const ZigGame = ziggame.ZigGame; // context
const sdl = @import("zig-game").sdl;
const game = @import("game/game.zig");

const SpriteFactory = game.sprite.Factory;

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
        event: sdl.Event,
        empty: void,
    };
    val: Event = .{ .empty = {} },
    is_empty: bool = true,

    fn init(event: sdl.Event) InputEvent {
        return .{
            .is_empty = false,
            .val = .{ .event = event },
        };
    }
};

const InputEvents = struct {
    ie_mouse_motion: InputEvent = .{},
    ie_mouse_button_down: InputEvent = .{},
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
    zg: *ZigGame,
    mixer: *game.mixer.Mixer,
    font: *game.font.Font,
    game_level: u16 = 1,
    game_difficulty: u16 = difficulty(1),
    lives: u64 = 0,
    scores: NameScores = NameScores.init(std.heap.page_allocator),
    player_score_edit_pos: usize = 0,
    game_state: GameState = GameState.GAME_OVER,
    game_state_ticker: game.time.Ticker,
    bat_ball_debounce_ticker: game.time.Ticker,
    bounds: sdl.Rectangle,
    animations: ziggame.sprite.Group(SpriteFactory.Type) = .{}, // falling brick, score sprite
    playfield: ziggame.sprite.Group(SpriteFactory.Type) = .{},
    bricks: ziggame.sprite.Group(SpriteFactory.Type) = .{},
    text: ziggame.sprite.Group(SpriteFactory.Type) = .{}, // high scores

    ball_idx: usize = 0,
    ball_start_y: i32 = 0,
    bat_idx: usize = 0,
    deadly_border_idx: usize = 0,

    input: InputEvents = .{},

    pub fn init(zg: *ZigGame, mixer: *game.mixer.Mixer, font: *game.font.Font) !GameContext {
        var gctx: GameContext = .{
            .zg = zg,
            .mixer = mixer,
            .font = font,
            .bounds = sdl.Rectangle{ .x = 0, .y = 0, .width = zg.size.width_pixels, .height = zg.size.height_pixels },
            .game_state_ticker = game.time.Ticker.init(),
            .bat_ball_debounce_ticker = game.time.Ticker.init(),
        };

        var bounds = gctx.bounds;
        var ball_canvas = try game.shape.ball(zg, game.constant.BALL_RADIUS);
        var ball = SpriteFactory.Bouncing.new(
            ball_canvas,
            bounds,
            -100,
            -100,
            0,
            0,
            0,
            gctx.mixer.ball_wall,
        );
        gctx.ball_idx = try gctx.playfield.add(ball);
        var bat_canvas = try game.shape.bat(zg);
        var bat = SpriteFactory.new(
            bat_canvas,
            @divTrunc(bounds.width, 2),
            bounds.height - 2 * game.constant.BRICK_HEIGHT,
        );
        gctx.bat_idx = try gctx.playfield.add(bat);
        var bottom_border_canvas = try game.shape.filled_rect(
            zg,
            game.constant.SCREEN_WIDTH,
            4,
            game.color.red,
        );
        var deadly_border = SpriteFactory.new(
            bottom_border_canvas,
            0,
            bounds.height - 4,
        );
        gctx.deadly_border_idx = try gctx.playfield.add(deadly_border);

        // 1st 3 are the high scores, the last is the current player score
        try gctx.scores.append(NameScore.init("AAA", 1000));
        try gctx.scores.append(NameScore.init("BBB", 100));
        try gctx.scores.append(NameScore.init("CCC", 10));
        try gctx.scores.append(NameScore.init("   ", 0));
        try replace_high_scores(&gctx);

        return gctx;
    }
};

fn get_screen_center(gctx: *GameContext) ziggame.Point {
    var x = @divTrunc(gctx.zg.size.width_pixels, 2);
    var y = @divTrunc(gctx.zg.size.height_pixels, 2);
    return .{ .x = x, .y = y };
}

fn get_screen_center_top(gctx: *GameContext) ziggame.Point {
    var x = @divTrunc(gctx.zg.size.width_pixels, 2);
    var y = @divTrunc(gctx.zg.size.height_pixels, 8);
    return .{ .x = x, .y = y };
}

// // event handlers
fn change_game_state_if_mouse_button_up(gctx: *GameContext, new_state: GameState) void {
    if (gctx.input.ie_mouse_button_down.is_empty) {
        return;
    }
    set_game_state(gctx, new_state); // state
    gctx.mixer.mouse_press.play();
}

fn process_mouse_motion(gctx: *GameContext) void {
    if (gctx.input.ie_mouse_motion.is_empty) {
        return;
    }

    var bat = &gctx.playfield.list.items[gctx.bat_idx];
    var data = bat.get();
    var batx = gctx.input.ie_mouse_motion.val.event.mouse_motion.x - @divTrunc(data.width, 2);
    data.x = batx;
    bat.set(data);
}

fn set_game_state(gctx: *GameContext, state: GameState) void {
    gctx.game_state = state;
    gctx.game_state_ticker.reset();
}

fn reset_ball(gctx: *GameContext) void {
    var pos = get_screen_center(gctx);
    var ball = &gctx.playfield.list.items[gctx.ball_idx];
    var data = ball.get();
    data.x = pos.x;
    data.y = gctx.ball_start_y;
    data.vel = gctx.game_difficulty + 3;
    data.dx = 1;
    data.dy = 1;
    ball.set(data);
}

fn difficulty(game_level: u16) u16 {
    return if (game_level > 10) 10 else game_level;
}

// state handlers
fn run_new_game(gctx: *GameContext) !void {
    gctx.lives = 3;
    gctx.game_level = 1;
    gctx.game_difficulty = difficulty(gctx.game_level);
    var player_ns = gctx.scores.items[PLAYER_SCORE_IDX];
    player_ns.score = 0;
    player_ns.set_name("   ");
    gctx.player_score_edit_pos = 0;
    try replace_bricks(gctx);
    set_game_state(gctx, GameState.GET_READY);
}

fn run_attract(gctx: *GameContext) !void {
    var point = get_screen_center(gctx);

    if (gctx.game_state_ticker.counter_ms <= 2000) {
        try game.text.draw_centered(gctx.zg, "Press Mouse Button", point, 4);
    } else if ((2000 <= gctx.game_state_ticker.counter_ms) and (gctx.game_state_ticker.counter_ms <= 4000)) {
        try game.text.draw_centered(gctx.zg, "To Start", point, 4);
    } else {
        set_game_state(gctx, GameState.SHOW_HIGH_SCORES);
    }

    change_game_state_if_mouse_button_up(gctx, GameState.NEW_GAME);
}

fn run_show_high_scores(gctx: *GameContext) !void {
    if (gctx.game_state_ticker.counter_ms >= 10000) {
        set_game_state(gctx, GameState.ATTRACT);
    }

    change_game_state_if_mouse_button_up(gctx, GameState.NEW_GAME);
}

fn draw_level_lives_score(gctx: *GameContext) !void {
    var player_ns = gctx.scores.items[PLAYER_SCORE_IDX];
    const string = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "Level: {d} Lives: {d} Score: {d}",
        .{ gctx.game_level, gctx.lives, player_ns.score },
    );
    //try game.text.draw(gctx.zg, string, .{ .x = 4, .y = 4 }, 2);
    //try ziggame.font.render(gctx.zg, string, 4, 4, 2, game.color.cyan);
    try gctx.font.render(string, 4, 4);
    defer std.heap.page_allocator.free(string);
}

fn update_screen(gctx: *GameContext) void {
    gctx.bricks.update();
    if (!((gctx.game_state == GameState.LIFE_LOST) or (gctx.game_state == GameState.LEVEL_COMPLETE))) {
        // restrict ball movement/animation
        gctx.playfield.update();
    }
    gctx.animations.update();
    gctx.text.update();
}

fn draw_screen(gctx: *GameContext) !void {
    gctx.bricks.draw(gctx.zg);
    gctx.playfield.draw(gctx.zg);
    gctx.animations.draw(gctx.zg);
    if (gctx.game_state == GameState.SHOW_HIGH_SCORES) {
        gctx.text.draw(gctx.zg);
    }
    try draw_level_lives_score(gctx);
}

fn handle_ball_bat_collision(gctx: *GameContext, ball: *SpriteFactory.Type, bat: *SpriteFactory.Type) void {
    _ = bat;
    if (gctx.bat_ball_debounce_ticker.counter_ms < 100) {
        // zg.util.log("debounce {}\n", .{gctx.bat_ball_debounce_ticker.counter_ms});
        return;
    }
    gctx.bat_ball_debounce_ticker.reset();

    var ball_data = ball.get();
    ball_data.dy = -ball_data.dy;
    ball.set(ball_data);
    gctx.mixer.ball_bat.play();
}

fn collision(s1: *SpriteFactory.Type, s2: *SpriteFactory.Type) bool {
    return s1.position_rect().hasIntersection(s2.position_rect());
}

fn run_game(gctx: *GameContext) !void {
    process_mouse_motion(gctx);

    var ball = &gctx.playfield.list.items[gctx.ball_idx];
    var bat = &gctx.playfield.list.items[gctx.bat_idx];
    var deadly_border = &gctx.playfield.list.items[gctx.deadly_border_idx];

    // handle brick/ball collision
    var result = gctx.bricks.collision(ball);
    if (result.collided) {
        var brick = result.item.?;
        var moving_brick = SpriteFactory.Moving.copy(brick);
        var brick_data = moving_brick.get();
        brick_data.dy = 1;
        brick_data.vel = 1;
        moving_brick.set(brick_data);
        _ = try gctx.animations.add(moving_brick);

        var moving_text = try SpriteFactory.Moving.text(gctx.zg, "+10", brick_data.x, brick_data.y, 1, 0, -1);
        _ = try gctx.animations.add(moving_text);

        _ = gctx.bricks.remove(result.index);

        var ball_data = ball.get();
        ball_data.dy = -ball_data.dy;
        ball.set(ball_data);
        var player_ns = &gctx.scores.items[PLAYER_SCORE_IDX];
        player_ns.score += 10;
        gctx.mixer.ball_brick.play();

        if (gctx.bricks.list.items.len == 0) {
            set_game_state(gctx, GameState.LEVEL_COMPLETE);
            gctx.mixer.level_complete.play();
        }
    }

    // handle bat/ball collision
    if (collision(ball, bat)) {
        handle_ball_bat_collision(gctx, ball, bat);
    }

    // handle deadly border/ball collision
    if (collision(ball, deadly_border)) {
        set_game_state(gctx, GameState.LIFE_LOST);
        gctx.mixer.life_lost.play();
    }

    if (gctx.game_state_ticker.counter_ms > 20000) { // speed up the ball
        gctx.game_state_ticker.reset();
        var ball_data = ball.get();
        if (ball_data.vel < 20) { // maximum speed clamp
            ball_data.vel += 1;
            ball.set(ball_data);
        }
    }
}

fn run_life_lost(gctx: *GameContext) !void {
    if (gctx.game_state_ticker.counter_ms <= 2000) {
        var point = get_screen_center(gctx);
        if (gctx.lives == 1) {
            try game.text.draw_centered(gctx.zg, "No Lives Left!", point, 4);
        } else {
            try game.text.draw_centered(gctx.zg, "You Lost a Life!", point, 4);
        }
    } else {
        gctx.lives -= 1;
        if (gctx.lives > 0) {
            set_game_state(gctx, GameState.GET_READY);
            gctx.mixer.get_ready.play();
        } else {
            var player_ns = gctx.scores.items[PLAYER_SCORE_IDX];
            var idx: usize = 0;
            var high_score = false;
            for (gctx.scores.items) |ns| {
                if ((idx < PLAYER_SCORE_IDX) and player_ns.score > ns.score) {
                    high_score = true;
                }
                idx += 1;
            }
            if (high_score) {
                set_game_state(gctx, GameState.GAME_OVER_HIGH_SCORE);
                gctx.mixer.high_score.play();
            } else {
                set_game_state(gctx, GameState.GAME_OVER);
                gctx.mixer.game_over.play();
            }
        }
    }
}

fn run_get_ready(gctx: *GameContext) !void {
    process_mouse_motion(gctx);
    reset_ball(gctx);

    if (gctx.game_state_ticker.counter_ms < 2000) {
        var point = get_screen_center(gctx);
        var magnification: i32 = @intCast(i32, @divTrunc(gctx.game_state_ticker.counter_ms, 50));
        var size = if (magnification < 10) magnification else 20 - magnification;
        if (size > 0) {
            try game.text.draw_centered(gctx.zg, "Get Ready!", point, @intCast(u8, size));
        }
    } else {
        set_game_state(gctx, GameState.RUNNING);
    }
}

fn run_game_over(gctx: *GameContext) !void {
    gctx.bricks.draw(gctx.zg);
    try draw_level_lives_score(gctx);

    if (gctx.game_state_ticker.counter_ms < 2000) {
        var point = get_screen_center(gctx);
        var magnification: i32 = @intCast(i32, @divTrunc(gctx.game_state_ticker.counter_ms, 50));
        var size = if (magnification < 10) magnification else 20 - magnification;
        if (size > 0) {
            try game.text.draw_centered(gctx.zg, "Game Over", point, @intCast(u8, size));
        }
    } else {
        set_game_state(gctx, GameState.ATTRACT);
    }
}

fn run_game_over_high_score(gctx: *GameContext) !void {
    var point = get_screen_center(gctx);
    if (gctx.game_state_ticker.counter_ms <= 2000) {
        try game.text.draw_centered(gctx.zg, "Congratulations!", point, 4);
    } else if (gctx.game_state_ticker.counter_ms <= 4000) {
        try game.text.draw_centered(gctx.zg, "New High Score!", point, 4);
    } else {
        set_game_state(gctx, GameState.ENTER_HIGH_SCORE);
    }
}

fn run_next_level(gctx: *GameContext) !void {
    gctx.game_level += 1;
    set_game_state(gctx, GameState.GET_READY);
    gctx.mixer.get_ready.play();
    gctx.animations.destroy(); // run once per level as bricks share a texture
    try replace_bricks(gctx);
}

fn run_level_complete(gctx: *GameContext) !void {
    var point = get_screen_center(gctx);
    try game.text.draw_centered(gctx.zg, "Level Complete!", point, 3);

    if (gctx.game_state_ticker.counter_ms > 2000) {
        set_game_state(gctx, GameState.NEXT_LEVEL);
    }
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

    var scaled_char_wh: i32 = 8 * game.constant.MEDIUM_TEXT_SCALE;

    var point = get_screen_center(gctx);
    try game.text.draw_centered(gctx.zg, "Enter Your Name", point, game.constant.MEDIUM_TEXT_SCALE);

    var char: u8 = 0;

    // TODO: handle shift modifier
    if (!gctx.input.ie_key_down.is_empty) { // handle keypresses

        gctx.mixer.key_press.play();

        //gctx.input.ie_key_down.ve.event.key_down.
        var key = gctx.input.ie_key_down.val.event.key_down;
        var scancode = key.scancode;
        var keycode = key.keycode;
        char = @intCast(u8, @enumToInt(keycode));

        if (scancode == sdl.Scancode.@"return") {
            std.sort.sort(NameScore, gctx.scores.items, {}, compareNameScoresAscending);
            try replace_high_scores(gctx);
            set_game_state(gctx, GameState.SHOW_HIGH_SCORES);
            return;
        }

        if (gctx.player_score_edit_pos > 0) {
            if (scancode == sdl.Scancode.backspace) {
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
    try game.text.draw(gctx.zg, player_name, .{ .x = text_x, .y = point.y + scaled_char_wh * game.constant.MEDIUM_TEXT_SCALE }, game.constant.MEDIUM_TEXT_SCALE);

    if (blink_on) {
        var cursor_x = text_x + @intCast(i32, gctx.player_score_edit_pos) * scaled_char_wh;
        try game.text.draw(gctx.zg, "_", .{ .x = cursor_x, .y = point.y + scaled_char_wh * game.constant.MEDIUM_TEXT_SCALE }, game.constant.MEDIUM_TEXT_SCALE);
    }
}

fn run_game_state(gctx: *GameContext) !bool {
    gctx.game_state_ticker.tick();
    gctx.bat_ball_debounce_ticker.tick();

    gctx.input = .{}; // clear last events

    while (sdl.pollEvent()) |event| {
        switch (event) {
            .quit => return false,
            .mouse_motion => {
                gctx.input.ie_mouse_motion = InputEvent.init(event);
            },
            .mouse_button_down => {
                gctx.input.ie_mouse_button_down = InputEvent.init(event);
            },
            .key_down => {
                gctx.input.ie_key_down = InputEvent.init(event);
            },
            else => {},
        }
    }

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
        .GAME_OVER_HIGH_SCORE => {
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
    gctx.text.list.clearAndFree();
    var vel: i32 = 1;
    var pos = get_screen_center(gctx);
    var tgrad: game.color.DualGradient = .{ .start = game.color.MIDBLUE_TO_LIGHTBLUE_GRADIENT, .end = game.color.RED_TO_ORANGE_GRADIENT };
    var title = try SpriteFactory.Scrolling.text_dual_gradient(gctx.zg, "Today's High Scores", tgrad, gctx.bounds, pos.x, pos.y, vel, 0, -1);
    //var tgrad: game.color.Gradient = game.color.RED_TO_ORANGE_GRADIENT;
    //var title = try SpriteFactory.Scrolling.text_gradient(gctx.zg, "Today's High Scores", tgrad, gctx.bounds, pos.x, pos.y, vel, 0, -1);
    var title_data = title.get();
    title_data.x -= title_data.width >> 1;
    title.set(title_data);
    _ = try gctx.text.add(title);

    var sgrad: game.color.DualGradient = .{ .start = game.color.ORANGE_TO_GOLD_GRADIENT, .end = game.color.GOLD_TO_ORANGE_GRADIENT };
    var scaled_char_wh: i32 = 8 * game.constant.MEDIUM_TEXT_SCALE;

    var yoff: i32 = scaled_char_wh * 2;
    const spacing = 8;
    var idx: usize = 0;
    for (gctx.scores.items) |_| {
        if (idx < PLAYER_SCORE_IDX) {
            //var score_text = try std.fmt.allocPrint(std.heap.page_allocator, "{s}    {}", .{ ns.name, ns.score });
            var name_sprite = try SpriteFactory.Scrolling.text_dual_gradient(gctx.zg, &gctx.scores.items[idx].name, sgrad, gctx.bounds, pos.x - scaled_char_wh * spacing, pos.y + yoff, vel, 0, -1);
            _ = try gctx.text.add(name_sprite);

            var score_text = try std.fmt.allocPrint(std.heap.page_allocator, "{}", .{gctx.scores.items[idx].score});
            var score_max_chars: i32 = spacing;
            var score_text_len = @intCast(i32, score_text.len);
            var rhs = score_max_chars - score_text_len;
            var score_x = pos.x + scaled_char_wh * rhs;
            //dbg("{}, {}, {}: {}\n", .{ score_max_chars, score_text_len, rhs, score_x });
            var score_sprite = try SpriteFactory.Scrolling.text_dual_gradient(gctx.zg, score_text, sgrad, gctx.bounds, score_x, pos.y + yoff, vel, 0, -1);
            _ = try gctx.text.add(score_sprite);
            yoff = yoff + scaled_char_wh;
        }
        idx += 1;
    }
}

fn replace_bricks(gctx: *GameContext) !void {
    gctx.bricks.destroy();

    //testing
    // var canvas = try game.shape.brick(gctx.zg, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, 0);
    // try gctx.bricks.list.append(SpriteFactory.new(canvas, 350, 200));
    var count: i32 = 0;
    var bricks_y_offset: i32 = game.constant.BRICK_HEIGHT * (gctx.game_difficulty + 5);
    var r: i32 = 0;
    while (r != game.constant.NUM_BRICK_ROWS) : (r += 1) {
        var canvas = try game.shape.brick(gctx.zg, game.constant.BRICK_WIDTH, game.constant.BRICK_HEIGHT, r);
        var c: i32 = 0;
        while (c != game.constant.BRICKS_PER_ROW) : (c += 1) {
            var x = @intCast(i32, c * game.constant.BRICK_WIDTH);
            var y = bricks_y_offset + r * game.constant.BRICK_HEIGHT;
            gctx.ball_start_y = y;
            var brick = SpriteFactory.new(canvas, x, y);
            try gctx.bricks.list.append(brick);
            count += 1;
        }
    }

    gctx.ball_start_y += game.constant.BRICK_HEIGHT;
}

fn stats(gctx: *GameContext) void {
    var num_inactive: i32 = 0;
    for (gctx.animations.list.items) |item| {
        var data = item.get();
        if (data.state < 0) {
            num_inactive += 1;
        }
    }

    dbg("animations - count: {}, inactive: {}", .{ gctx.animations.list.items.len, num_inactive });
}

pub fn main() !void {
    var zgContext = try ZigGame.init("breakout", game.constant.SCREEN_WIDTH, game.constant.SCREEN_HEIGHT);
    var mixer = try game.mixer.Mixer.init();
    var font = try game.font.Font.init(&zgContext);
    var gctx = try GameContext.init(&zgContext, &mixer, &font);
    try replace_bricks(&gctx);
    set_game_state(&gctx, GameState.GAME_OVER);
    //set_game_state(&gctx, GameState.ENTER_HIGH_SCORE);
    reset_ball(&gctx);
    var renderer = gctx.zg.renderer;
    var running: bool = true;
    while (running) {
        try renderer.setColor(game.color.SCREEN_COLOR);
        try renderer.clear();
        update_screen(&gctx);
        running = try run_game_state(&gctx);
        try draw_screen(&gctx);
        gctx.zg.renderer.present();
        //stats(&gctx);
    }

    ziggame.quit();
}
