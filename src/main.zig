const std = @import("std");
const gs = @import("Games/First Attempt/game_state.zig");
const cs = @import("Games/First Attempt/card_stack.zig");
const pso = @import("PSO/swarm.zig");
const ga = @import("GA/genetic_algorithm.zig");
const bitDeckVector = @import("Games/bitdeck_vector.zig");
const bitDeckRaw = @import("Games/bitdeck_raw.zig");
const games = @import("Games/evaluate_representations.zig");
const bt = @import("bittwidling.zig");
const p = @import("print.zig");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    const start = std.time.nanoTimestamp();

    try doSomething(stdout);

    const end = std.time.nanoTimestamp();
    const duration_ns:u64 = @intCast(end - start);
    // Print elapsed time
    const seconds = duration_ns / 1_000_000_000;
    const milliseconds = (duration_ns % 1_000_000_000) / 1_000_000;
    const nanoseconds = duration_ns % 1_000_000;
    try stdout.print("Elapsed time: {}s:{}ms:{}ns\n", .{ seconds, milliseconds, nanoseconds });
    try bw.flush(); // don't forget to flush!
}

fn benchmark() void{
    const rand = std.crypto.random;
    const b = rand.int(u8);
    for (0..1_000_000_000)|_|{
        // const rev =bt.reverseBitsLoop(u8, b);
        // const rev = bt.reverseByte(b);
        const rev = bt.REVERSE_BYTE_TABLE[b];
        if (rev>0){}
    }
}

fn testing(stdout: anytype) !void{
    try stdout.print("Testing...\n", .{});
    // const move:u6 = 0b010010;
    // const face:u6 = 0b001010;
    // const pos1:u6 = 0b010001;
    // const pos2:u6 = 0b100100;
    // var mask = @as(u6,@intFromBool(move & pos1 != 0)) * ~@as(u6, 0);
    // const new_pos1:u6 = (((face ^ move) ^ pos1) & mask) | (pos1 & ~mask);
    // mask = @as(u6,@intFromBool(move & pos2 != 0)) * ~@as(u6, 0);
    // const new_pos2:u6 = (((face ^ move) ^ pos2) & mask) | (pos2 & ~mask);
    // try stdout.print("move:\t{b:0>6}\n", .{move});
    // try stdout.print("face:\t{b:0>6}\n", .{face});
    // try stdout.print("pos1:\t{b:0>6}\n", .{pos1});
    // try stdout.print("pos1:\t{b:0>6}\n", .{new_pos1});
    // try stdout.print("pos2:\t{b:0>6}\n", .{pos2});
    // try stdout.print("pos2:\t{b:0>6}\n", .{new_pos2});
    var game = bitDeckVector.BitDeckRaw.init();
    var trick = game.trick+3;
    try p.printDeck(game, stdout);
    while(game.is_done == 0){
        game.step();
        if (trick != game.trick){
            try p.printDeck(game, stdout);
            trick = game.trick;
        }
        if (game.turn >= 10_000){break;}
    }
    try p.printStats(game, stdout);
    // benchmark();
}

fn doSomething(stdout: anytype) !void{
    try stdout.print("Doing Something...\n", .{});
    // try testing(stdout);
    // try tryGames(stdout);
    try bitGames(stdout);

    // games.evaluateGameRepresentation(bitDeck.BitDeck);
    // games.evaluateGameRepresentation(bitDeckRaw.BitDeckRaw);

    // try trySwarm(stdout);
    // try tryGA(stdout);
}

fn bitGames(stdout: anytype) !void{
    var testGame = bitDeckVector.BitDeckRaw.init();
    var longestGame = testGame;
    for (0..1_000) |_|{
        testGame.reset();
        testGame.shuffleDeck();
        testGame.play();
        if (longestGame.turn < testGame.turn) {
            try stdout.print("{}->{}\n", .{longestGame.turn, testGame.turn});
            longestGame = testGame;
        }
    }
    longestGame.restart();
    try p.printDeck(&longestGame, stdout);
    longestGame.play();
    try p.printStats(&longestGame, stdout);
}

fn trySwarm(stdout: anytype) !void{
    var swarm: pso.Swarm = pso.Swarm{};
    swarm.init(0.8,0.1,0.2);
    try swarm.runSwarm();
    try swarm.playBestGame(stdout);
    try stdout.print("Swarm stats:\n",.{});
    try stdout.print("\t Steps: {}\n",.{swarm.steps});
    try stdout.print("\t Score: {}\n",.{swarm.best_score});
}

fn tryGA(stdout: anytype) !void{
    var population: ga.Population = ga.Population{};
    population.init();
    try population.runEvolution();
    try population.playBestGame(stdout);
    try stdout.print("Population stats:\n",.{});
    try stdout.print("\t Generations: {}\n",.{population.gen});
    try stdout.print("\t Best Score: {}\n",.{population.best_score});
}


fn tryGames(stdout: anytype) !void{
    var testGame = gs.GameState{};
    var longestGame = testGame;
    for (0..1_000_000) |_|{
        testGame.init();
        while (testGame.is_active){
            testGame.playTrick();
        }
        if (longestGame.turn < testGame.turn) {longestGame = testGame;}
    }
    try stdout.print("Longest game:\n",.{});
    // try longestGame.print(stdout);
    longestGame.reset();
    try longestGame.print(stdout);
    try stdout.print("\n",.{});
    while (longestGame.is_active){
        longestGame.playTrick();
        // try longestGame.printHands(stdout);
    }
    try longestGame.print(stdout);
}