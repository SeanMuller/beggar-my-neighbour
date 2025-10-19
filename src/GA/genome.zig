const std = @import("std");
const bit = @import("../bittwidling.zig");

fn generateRandomVector(T: type, max: T) [16]T{
    const rand = std.crypto.random;
    var temp :[16]T = undefined;
    for (0..temp.len) |i|{
        if (@typeInfo(T) == .Float){
            temp[i] = rand.float(f32);
        } else if (@typeInfo(T) == .Int) {
            temp[i] = rand.intRangeAtMost(T, 0, max);
        }
    }
    return temp;
}

pub fn printVector(vec: anytype, writer: anytype) !void {
    const len = vec.len;
    try writer.print("[", .{});
    for (0..len) |i| {
        try writer.print("{:.2}", .{vec[i]});
        if (i < len-1) try writer.print(", ", .{});
    }
    try writer.print("]\n", .{});
}

pub fn posToString(pos: [16]u8) [52]u8{
    var string: [52]u8 = [_]u8{'-'} ** 52;
    for (pos, 0..)|val, i|{
        switch (i/4){
            0 =>{string[val]= 'J';},
            1 =>{string[val]= 'Q';},
            2 =>{string[val]= 'K';},
            3 =>{string[val]= 'A';},
            else =>{string[val]= '-';}
        }
    }
    return string;
}

pub const Genome = struct{
    dna:[16]u8 = undefined,
    fitness: u64 = 0,

    pub fn init(g: *Genome) void{
        g.dna = generateRandomVector(u8, 51);
    }

    pub fn hash(self: @This()) u64 {
        return std.hash.hash(self.dna);
    }

    pub fn eql(self: @This(), other: @This()) bool {
        return std.mem.eql(u8, &self.dna, &other.dna);
    }

    pub fn mutate(g: *Genome, rate: f32) void{
        var bits = std.StaticBitSet(52).initEmpty();
        // Get current position
        for (0..g.dna.len) |i| {
            bits.set(g.dna[i]);
        }
        // Mutate position
        const rand = std.crypto.random;
        for (0..g.dna.len) |i| {
            // Check if card position should be mutated
            if (rand.float(f32) > rate){
                continue;
            }

            const currentPos = g.dna[i];
            var foundOpenPos = false;
            // Randomly look for a new position
            while (!foundOpenPos){
                const newPos = rand.uintAtMost(u8, 51);
                if (bits.isSet(newPos)){continue;}
                foundOpenPos = true;
                g.dna[i] = newPos;
                bits.unset(currentPos);
                bits.set(newPos);
            }
            g.fitness = 0;
        }
    }

    pub fn validate(g: *Genome) bool{
        var bits = std.StaticBitSet(52).initEmpty();
        var val:u8 = 0;
        for (0..g.dna.len) |i| {
            if (g.dna[i] < 0 ){g.dna[i] = 0;}
            if (g.dna[i] > 51 ){g.dna[i] = 51;}
            val = g.dna[i];
            if (bits.isSet(val)){return false;}
            bits.set(val);
        }
        if (bits.count() != 16){return false;}
        return true;
    }

    pub fn print(g: *Genome, writer: anytype) !void{
        try writer.print("DNA: ",.{});
        try printVector(g.dna, writer);
    }

    pub fn fixDNA(g: *Genome) void{
        var bits = std.StaticBitSet(52).initEmpty();
        var val: u8 =0;
        for (0..g.dna.len) |i| {
            if (g.dna[i] < 0 ){g.dna[i] = 0;}
            if (g.dna[i] > 51 ){g.dna[i] = 51;}
            val = g.dna[i];
            if (bits.isSet(val)){
                var replacement = @as(i8,@intCast(val));
                var dir:i8 = 1;
                var hasSwappedDir = false;
                while (0 <= replacement and replacement < 52) : (replacement += dir){
                    if (bits.isSet(@as(usize,@intCast(replacement))) == false){
                        bits.set(@as(usize,@intCast(replacement)));
                        break;
                    }
                    if (replacement == 0 or replacement == 51){
                        replacement = @as(i8,@intCast(val));
                        dir = -dir;
                    }
                    if (hasSwappedDir and (replacement == 0 or replacement == 51)){
                        std.debug.print("{}, {}\n", .{val, dir});
                        for(g.dna)|pval|{
                            std.debug.print("{} ", .{pval});
                        }
                        @panic("No unused numbers available");
                    }
                    hasSwappedDir = true;
                }
            }
            bits.set(val);
        }
    }
};