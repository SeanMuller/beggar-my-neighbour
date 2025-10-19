const std = @import("std");
const bt= @import("../bittwidling.zig");

const Faces = enum {jack, queen, king, ace};
const V4u64 = @Vector(4, u64);
const V4u6 = @Vector(4, u6);
const DECK_MASK:u64 = 0xFFFFFFFFFFFFF;
const HALF_DECK_MASK: V4u64 = @splat(DECK_MASK >> 26);
const HALF_DECK_SHIFT:V4u6 = @splat(26);
const DECK_NO:usize = 4;
const PLAY_STACK:usize = 2;
pub const STARTING_DECK:usize = 3;
const DECK_POSITIONS:[52]u6 = .{
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
    10, 11, 12, 13, 14, 15, 16, 17, 18, 19,
    20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
    30, 31, 32, 33, 34, 35, 36, 37, 38, 39,
    40, 41, 42, 43, 44, 45, 46, 47, 48, 49,
    50, 51
};


pub const BitDeckRaw = struct{
    // One for each player and then the play stack, and the starting deck
    deck:[DECK_NO] V4u64 = undefined, 
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
        const hand_size = bd.hand_size[bd.player_turn];
        if (hand_size == 0){bd.is_done = 1; return;}

        const hand_combined:u64 = @reduce(.Or, bd.deck[bd.player_turn]);
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
                if (bd.deck[bd.player_turn][i] & (@as(u64,0x1) << next_face) > 0){
                    bd.battle = @as(u4,@intCast(i))+1;
                    break;
                }
            }
        }

        const shift_mask:u64 = (@as(u64,0x1) << play_length) - 1;
        
        //play hand
            const vec_shift_mask: V4u64 = @splat( shift_mask);
            const vec_play_stack_size: V4u6 = @splat(bd.hand_size[PLAY_STACK]);
            const vec_opp_hand_size: V4u6 = @splat(bd.hand_size[~bd.player_turn]);
            const vec_play_length: V4u6 = @splat(play_length);

            //put cards into the play stack
            bd.deck[PLAY_STACK] |= (vec_shift_mask & bd.deck[bd.player_turn]) << vec_play_stack_size; 
            //remove cards from the player hand
            bd.deck[bd.player_turn] = bd.deck[bd.player_turn] >> vec_play_length;
            if (lost_trick){
                //put cards into opposition hand
                bd.deck[~bd.player_turn] |= bd.deck[PLAY_STACK] << vec_opp_hand_size; 
                //clear play stack
                bd.deck[PLAY_STACK] = .{0, 0, 0, 0};
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
            bd.deck[0] = bd.deck[STARTING_DECK] & HALF_DECK_MASK;
            bd.deck[1] = (bd.deck[STARTING_DECK] & ~HALF_DECK_MASK) >> HALF_DECK_SHIFT;
            bd.deck[PLAY_STACK] = .{0, 0, 0, 0};
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
        bd.deck[0]= bd.deck[STARTING_DECK] & HALF_DECK_MASK;
        bd.deck[1] = (bd.deck[STARTING_DECK] & ~HALF_DECK_MASK) >> HALF_DECK_SHIFT;
    }
};