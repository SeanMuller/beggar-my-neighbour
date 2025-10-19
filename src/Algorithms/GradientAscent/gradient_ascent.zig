const std = @import("std");
const bdr = @import("../../Games/bitdeck_raw.zig");


pub fn avalancheTest() void{
    const bit_deck = bdr.BitDeckRaw.init();
    const h = hash(bit_deck.deck[bdr.STARTING_DECK]);
    const neighbours = generateNeighbouringMoves(bit_deck.deck[bdr.STARTING_DECK]);
    if(h>0){}
    if(neighbours > 0){}
}

inline fn hash(pos: [4]u64) u64{
    return (pos[0] * 0x9E3779B185EBCA87)
        ^ (pos[1] * 0xC2B2AE3D27D4EB4F)
        ^ (pos[2] * 0x165667B19E3779F9)
        ^ (pos[3] * 0x85EBCA6B);
}

fn applyMove(pos: [4]u64, move: u64, face:usize) [4]u64{
    var new_pos:[4]u64 = undefined;
    new_pos[face]= move;
    new_pos[1] = (move & pos[1] | & ~pos[face]) ^ pos[1];
} 

fn generateNeighbouringMoves(pos: [4]u64) [4][192]u64{
    var neighbours:[4][192]u64 = undefined;
    for (pos, 0..)|p,i|{
        generateNeighbouringNumbers(p, neighbours[i][0..]);
    }
}

fn generateNeighbouringNumbers(num:u64, buff:[]u64) void{
    var set_bit:usize = 0;
    for (0..52)|i|{
        const i_bit = (@as(u64, @intCast(0x1)) << i);
        if (num & i_bit == 0){continue;}
        var swap_bit = 0;
        for(0..52)|j|{
            const j_bit = (@as(u64, @intCast(0x1)) << j);
            if (num & j_bit != 0){continue;}
            buff[set_bit*48+swap_bit] = num ^ j_bit ^ i_bit;
            swap_bit += 1;
        }
        set_bit +=1;
    }
}