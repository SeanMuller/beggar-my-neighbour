const std = @import("std");
const bt= @import("../bittwidling.zig");

const Faces = enum {jack, queen, king, ace};
const DECK_MASK:u64 = 0xFFFFFFFFFFFFF;
const HALF_DECK_MASK: u64 = DECK_MASK >> 26;
const DECK_NO:usize = 4;
const PLAY_STACK:usize = 2;
pub const STARTING_DECK:usize = 3;


pub const BitDeckRaw = struct{
    // One for each player and then the play stack, and the starting deck
    deck:[DECK_NO][4]u64 = std.mem.zeroes([DECK_NO][4]u64), 
    hand_size: [3]u6 = std.mem.zeroes([3]u6),
    is_done:u1 = 0,
    battle:u4 = 0,
    player_turn: u1 = 0,
    // Stats
    turn:u32 =0,
    trick: u32 =0,

    pub fn init() BitDeckRaw{
        var bd =BitDeckRaw{};
        bd.reset();
        bd.shuffleDeck(); 
        return bd;
    }

    pub fn play(bd: *BitDeckRaw) void{
        while(bd.is_done == 0){
            bd.step();
            if (bd.turn >= 10_000){break;}
        }
    }

    pub fn step(bd: *BitDeckRaw) void{
        const hand = &bd.deck[bd.player_turn];
        const hand_size = bd.hand_size[bd.player_turn];
        if (hand_size == 0){bd.is_done = 1; return;}

        const hand_combined:u64 = hand[0]|hand[1]|hand[2]|hand[3];
        const next_face:u6 = if (hand_combined != 0) @as(u6,@intCast(@ctz(hand_combined))) else 62;
        const play_length:u6 = @min(next_face+1, @max(bd.battle,1));
        // Game lost because ran out of cards
        if (play_length > hand_size or (play_length == hand_size and next_face >= hand_size)){
            bd.is_done = 1;
            bd.trick +=1;
            bd.turn +=@min(play_length, hand_size);
            return;
        }
        const lost_trick:bool = if(bd.battle > 0 and next_face >= bd.battle) true else false;

        // if a face card is played set battle count
        if (next_face < play_length){
            for (0..4)|i|{
                if (hand[i] & (@as(u64,0x1) << next_face) > 0){
                    bd.battle = @as(u4,@intCast(i))+1;
                    break;
                }
            }
        }

        const shift_mask:u64 = (@as(u64,0x1) << play_length) - 1;
        
        //play hand
        for (hand, 0..)|*face,i|{
            //put cards into the play stack
            bd.deck[PLAY_STACK][i] |= (shift_mask & face.*) << bd.hand_size[PLAY_STACK]; 
            //remove cards from the player hand
            face.* = face.* >> play_length;
            if (lost_trick){
                //put cards into opposition hand
                bd.deck[~bd.player_turn][i] |= bd.deck[PLAY_STACK][i] << bd.hand_size[~bd.player_turn]; 
                //clear play stack
                bd.deck[PLAY_STACK][i] = 0;
            }
        }
        bd.hand_size[bd.player_turn] -= play_length;
        bd.hand_size[PLAY_STACK] += play_length;
        if (lost_trick){
            bd.trick +=1;
            bd.hand_size[~bd.player_turn] += bd.hand_size[PLAY_STACK];
            bd.hand_size[PLAY_STACK] = 0;
            bd.battle = 0;
        }
        bd.turn +=play_length;
        bd.player_turn = ~bd.player_turn;
    }

    pub fn reset(bd: *BitDeckRaw) void{
        bd.deck = std.mem.zeroes([DECK_NO][4]u64);
        bd.restart();
    }

    pub fn restart(bd: *BitDeckRaw) void{
        for (0..4)|i|{
            bd.deck[0][i] = bd.deck[STARTING_DECK][i] & HALF_DECK_MASK;
            bd.deck[1][i] = (bd.deck[STARTING_DECK][i] & ~HALF_DECK_MASK) >> 26;
            bd.deck[PLAY_STACK][i] = 0;
        }
        bd.hand_size[0] = 26;
        bd.hand_size[1] = 26;
        bd.hand_size[PLAY_STACK] = 0;
        bd.is_done = 0;
        bd.player_turn = 0;
        bd.battle = 0;
        bd.turn =0;
        bd.trick =0;
    }

    pub fn shuffleDeck(bd: *BitDeckRaw) void{
        const d = &bd.deck[STARTING_DECK];
        var rand =std.crypto.random;
        for (0..4)|i|{
            const occupied:u64 = d[0]|d[1]|d[2]|d[3];
            while (@popCount(d[i]) < 4){
                const  pos= rand.int(u6);
                if (pos<52 and (occupied | d[i]) & @as(u64,0x1)<<pos == 0){
                    d[i] = d[i] | @as(u64,0x1)<<pos;
                }
            }
        }
        for (0..4)|i|{
            bd.deck[0][i] = bd.deck[STARTING_DECK][i] & HALF_DECK_MASK;
            bd.deck[1][i] = (bd.deck[STARTING_DECK][i] & ~HALF_DECK_MASK) >> 26;
        }
    }
};