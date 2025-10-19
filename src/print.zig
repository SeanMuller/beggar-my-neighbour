const bdr = @import("Games/bitdeck_raw.zig");
const std = @import("std");


pub fn printStats(bd: anytype, stdout: anytype) !void{
    try stdout.print("Turns: {}\n", .{bd.turn});
    try stdout.print("Tricks: {}\n", .{bd.trick});
    try stdout.print("Final Hand: ", .{});
    try printDeck(bd, stdout);
}

pub fn printDeck(bd: anytype, stdout: anytype) !void{
    try stdout.print("'", .{});
    try printHand(bd, 0, stdout);
    try stdout.print("','", .{});
    try printHand(bd, 1, stdout);
    try stdout.print("'\n", .{});
}

pub fn printHand(bd: anytype,hand:usize, stdout: anytype) !void{
    for(0..bd.hand_size[hand])|i|{
        for(0..4)|j|{
            if (bd.deck[hand][j] & @as(u64,0x1) << @as(u6,@intCast(i)) > 0){
                switch (j) {
                    0 => {try stdout.print("J", .{});},
                    1 => {try stdout.print("Q", .{});},
                    2 => {try stdout.print("K", .{});},
                    3 => {try stdout.print("A", .{});},
                    else => {}
                }
                break;
            }
            if (j == 3){try stdout.print("-", .{});}
        }
    }
}


pub fn printBin(bd: *bdr.BitDeckRaw, stdout: anytype) !void{
    var deck:usize = 0;
    try stdout.print("Player 1\n", .{});
    for(0..4)|i|{
        switch (i) {
            0 => {try stdout.print("\tJ: ", .{});},
            1 => {try stdout.print("\tQ: ", .{});},
            2 => {try stdout.print("\tK: ", .{});},
            3 => {try stdout.print("\tA: ", .{});},
            else => {}
        }
        try std.fmt.formatInt(
            bd.deck[deck][i],
            2,
            .lower,
            .{
                .width = 26,
                .fill = '0',
                .alignment = .right,
            },
            stdout
        );
        try stdout.print("\n", .{});
    }
    deck = 1;
    try stdout.print("\nPlayer 2\n", .{});
    for(0..4)|i|{
        switch (i) {
            0 => {try stdout.print("\tJ: ", .{});},
            1 => {try stdout.print("\tQ: ", .{});},
            2 => {try stdout.print("\tK: ", .{});},
            3 => {try stdout.print("\tA: ", .{});},
            else => {}
        }
        try std.fmt.formatInt(
            bd.deck[deck][i],
            2,
            .lower,
            .{
                .width = 26,
                .fill = '0',
                .alignment = .right,
            },
            stdout
        );
        try stdout.print("\n", .{});
    }
    deck = 2;
    try stdout.print("\nPlay Stack\n", .{});
    for(0..4)|i|{
        switch (i) {
            0 => {try stdout.print("\tJ", .{});},
            1 => {try stdout.print("\tQ", .{});},
            2 => {try stdout.print("\tK", .{});},
            3 => {try stdout.print("\tA", .{});},
            else => {}
        }
        try stdout.print(": {b}\n", .{bd.deck[deck][i]});
    }
}