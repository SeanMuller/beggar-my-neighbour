const std = @import("std");
const cs = @import("card_stack.zig");

pub const GameState = struct {
    player_turn: u1 = 0,
    turn: u64 = 0,
    tricks: u64 = 0,
    is_active: bool = true,
    player_hands: [2]cs.CardStack = .{cs.CardStack{},cs.CardStack{}},
    play_stack: cs.CardStack = cs.CardStack{},
    starting_deck: cs.CardStack = cs.CardStack{},
    
    pub fn init(self: *GameState) void{
        self.starting_deck.shuffleDeck();
        self.reset();
    }

    pub fn reset(self: *GameState) void{
        self.player_turn = 0;
        self.turn = 0;
        self.tricks = 0;
        self.is_active = true;
        self.player_hands[0].len =0;
        self.player_hands[1].len =0;
        self.play_stack = self.starting_deck;
        self.play_stack.playCard(&self.player_hands[0], cs.DECK_SIZE/2);
        self.play_stack.playCard(&self.player_hands[1], cs.DECK_SIZE/2);
    }

    pub fn playGame(self: *GameState) void{
        while (self.is_active){
            self.playTrick();
        }
    }
    
    pub fn playTrick(self: *GameState) void{
        var attempts:u4 = 1;
        var isNumbered = false;
        var hasStarted = false;

        while (attempts>0){
            if (isNumbered){attempts = attempts - 1;}
            const player_hand = &self.player_hands[self.player_turn];
            
            // Infinite loop
            if (self.turn >= 100000){
                std.debug.print("ERROR. infinite loop", .{});
                self.is_active = false;
                break;
            }

            // You have no cards left. Game over.
            if (player_hand.len <= 0){
                self.is_active=false;
                self.tricks+= @intFromBool(hasStarted);
                self.play_stack.playCard(&self.player_hands[~self.player_turn], self.play_stack.len);
                break;
            }

            player_hand.playCard(&self.play_stack, 1);
            hasStarted = true;
            const played_card = self.play_stack.stack[self.play_stack.len-1];
            self.turn +=1;

            // You played a number card
            if ( played_card != 0){
                attempts = played_card;
                isNumbered = true;
                self.player_turn = ~self.player_turn;
                continue;
            }

            // Reached the end of the trick
            if (attempts == 0){
                if (player_hand.len <= 0){self.is_active=false;}
                self.player_turn = ~self.player_turn;
                self.play_stack.playCard(&self.player_hands[self.player_turn], self.play_stack.len);
                self.tricks +=1;
                break;
            }

            // You played 0 but numbers haven't started
            if (!isNumbered){self.player_turn = ~self.player_turn;}
        }
    }

    pub fn printHands(self: *const GameState, writer: anytype) !void {
        try writer.print("Turn : {}.\t", .{self.turn});
        try self.player_hands[0].printPretty(writer);
        try writer.print("/", .{});
        try self.player_hands[1].printPretty(writer);
        try writer.print("/\n", .{});
    }

    pub fn print(self: *const GameState, writer: anytype) !void {
        try writer.print("Player Turn: {}\n", .{self.player_turn});
        try writer.print("Turn: {}\n", .{self.turn});
        try writer.print("Tricks: {}\n", .{self.tricks});

        try writer.print("Starting Deck ({}): ", .{self.starting_deck.len});
        try self.starting_deck.printPretty(writer);
        try writer.print("\n'", .{});
        try self.player_hands[0].printPretty(writer);
        try writer.print("','", .{});
        try self.player_hands[1].printPretty(writer);
        try writer.print("'\n", .{});
    }
};