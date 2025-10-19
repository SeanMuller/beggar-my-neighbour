const part = @import("particle.zig");
const gs = @import("../Games/First Attempt/game_state.zig");
const std = @import("std");

const SIZE:usize = 100;
const GOAL:usize = 4792;
const MAX_STEPS:usize = 500;

pub const Swarm = struct {
    particles: [SIZE]part.Particle = undefined,
    best_position:[16]u8 = undefined,
    best_score: u64 = 0,
    inertia: f32 = 1,
    cognitive_coef: f32 = 1,
    social_coef: f32 = 1,
    game: gs.GameState = undefined,
    steps:u32 = 0,

    pub fn init(s: *Swarm, inertia: f32, cog_coef: f32, soc_coef: f32) void{
        s.game.init();
        s.particles = [_]part.Particle{.{}} ** SIZE;
        s.cognitive_coef = cog_coef;
        s.social_coef = soc_coef;
        s.inertia = inertia;
        s.steps = 0;

        for(0..SIZE)|i|{
            s.particles[i].init(s.inertia, s.cognitive_coef, s.social_coef);
        }
    }

    pub fn runSwarm(s: *Swarm) !void{
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();
        const now = std.time.timestamp();
        const filename = try std.fmt.allocPrint(
            allocator, 
            "logs/pso/{}-{}-{}.txt",
            .{SIZE, MAX_STEPS, now}
        );
        defer allocator.free(filename);
        const file = try std.fs.cwd().createFile(filename, .{.truncate=true});
        defer file.close();

        while (s.best_score < GOAL and s.steps < MAX_STEPS): (s.steps+=1){
            for (0..SIZE)|i|{
                s.particles[i].updateVelocity(&s.best_position);
                s.particles[i].move();
            }
            const old_score = s.best_score;
            s.evaluate();
            if (old_score != s.best_score){
                try file.writer().print(
                    "{}, {}, {s}\n",
                    .{s.steps, s.best_score, part.posToString(s.best_position)}
                );
            }
        }
    }

    pub fn playBestGame(s: *Swarm, writer: anytype) !void{
        s.game.starting_deck.stack = convertToDeckStack(&s.best_position);
        s.game.reset();
        try s.game.print(writer);
        s.game.playGame();
        try s.game.print(writer);
    }

    fn evaluate(s: *Swarm) void{
        for(0..SIZE)|i|{
            const p =&s.particles[i];
            s.game.starting_deck.stack = convertToDeckStack(&p.position);
            s.game.reset();
            s.game.playGame();
            if (s.game.turn > p.best_score){
                p.best_score = s.game.turn;
                p.best_position = p.position;
                if (s.game.turn > s.best_score){
                    s.best_score = s.game.turn;
                    s.best_position = p.position;
                }
            }
        }
    }

    fn convertToDeckStack(p: *[16]u8) [52]u4{
        var starting_deck = [_]u4{0} ** 52;
        for (p, 0..)|val, i|{
            starting_deck[val] = @as(u4,@intCast(i/4 + 1));
        }
        return starting_deck;
    }
};