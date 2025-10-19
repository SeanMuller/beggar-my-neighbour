const std = @import("std");

pub const DECK_SIZE = 52;

const DECK= [DECK_SIZE]u4{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
    1, 1, 1, 1,
    2, 2, 2, 2,
    3, 3, 3, 3,
    4, 4, 4, 4,
};


pub const CardStack = struct{
    stack: [DECK_SIZE]u4 =[_]u4{0} ** 52,
    len: usize = 0,

    pub fn shuffleDeck(self: *CardStack) void{
        std.mem.copyForwards(u4, self.stack[0..], DECK[0..]);
        self.len = DECK_SIZE;
        std.crypto.random.shuffle(u4, &self.stack);
    }

    pub fn playCard(self: *CardStack, stack: *CardStack, count:usize) void{
        std.mem.copyForwards(u4, stack.stack[stack.len..stack.len+count], self.stack[0..count]);
        stack.len = stack.len+count;
        self.len = if (count <= self.len) self.len-count else 0;
        std.mem.copyForwards(u4, self.stack[0..self.len], self.stack[count..count+self.len]);
    }

    pub fn print(self: *const CardStack, writer: anytype) !void {
        for (self.stack[0..self.len]) |card| {
            try writer.print("{} ", .{card});
        }
    }

    pub fn printPretty(self: *const CardStack, writer: anytype) !void {
        for (self.stack[0..self.len]) |card| {
            var char:u8 = '-';
            switch (card) {
                1 =>{char = 'J';},
                2 =>{char = 'Q';},
                3 =>{char = 'K';},
                4 =>{char = 'A';},
                else =>{char = '-';}
            }
            try writer.print("{c}", .{char});
        }
    }
};

