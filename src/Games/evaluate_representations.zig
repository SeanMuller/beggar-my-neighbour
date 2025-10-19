const std = @import("std");

const RUNS= 1_000_000;

pub fn evaluateGameRepresentation(comptime GameType: type) void{
    var game = GameType.init();
    const start = std.time.nanoTimestamp();

    for (0..RUNS)|_|{
        game.reset();
        while(game.is_done == 0){
            game.step();
        }
    }
    const end = std.time.nanoTimestamp();
    const duration_ns:u64 = @intCast(end - start);
    const seconds = duration_ns / 1_000_000_000;
    const milliseconds = (duration_ns % 1_000_000_000) / 1_000_000;
    const nanoseconds = duration_ns % 1_000_000;
    std.debug.print("{s} took {}s:{}ms:{}ns to do {} runs\n",
    .{
        @typeName(GameType),
        seconds, milliseconds, nanoseconds,
        RUNS
    }
    );
}