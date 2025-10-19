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

fn vectorTanh(vec: *[16]f32) [16]f32{
    var temp:[16]f32 = undefined; 
    for (0..16) |i| {
        temp[i] = std.math.tanh(vec[i]);
    }
    return temp;
}

fn generateMovementVector(velocity: *[16]f32) [16]i8{
    const velocity_probabilty = vectorTanh(velocity);
    const probability_vector = generateRandomVector(f32, 1);
    var movementVector:[16]i8 = undefined;
    for (0..16) |i|{
        movementVector[i] = @as(i8,@intFromFloat(std.math.sign(velocity[i])))
            * @as(i8,@intFromBool((probability_vector[i] <= @abs(velocity_probabilty[i]))));
    }
    return movementVector;
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

pub const Particle = struct{
    position:[16]u8 = undefined,
    velocity: [16]f32 = undefined,
    best_position:[16]u8 = undefined,
    best_score: u64 = 0,
    inertia: f32 = 1,
    cognitive_coef: f32 = 1,
    social_coef: f32 = 1,

    pub fn init(p: *Particle, inertia: f32, cog_coef: f32, soc_coef: f32) void{
        p.position = generateRandomVector(u8, 52);
        p.best_position = generateRandomVector(u8, 52);
        p.velocity = generateRandomVector(f32, 1);
        p.inertia = inertia;
        p.cognitive_coef = cog_coef;
        p.social_coef = soc_coef;
    }

    pub fn validate(p: *Particle) bool{
        var bits = std.StaticBitSet(52).initEmpty();
        var val:u8 = 0;
        for (0..p.position.len) |i| {
            if (p.position[i] < 0 ){p.position[i] = 0;}
            if (p.position[i] > 51 ){p.position[i] = 51;}
            val = p.position[i];
            if (bits.isSet(val)){return false;}
            bits.set(val);
        }
        if (bits.count() != 16){return false;}
        return true;
    }

    pub fn updateVelocity(p: *Particle, global_best: *[16]u8) void{
        var mag: f32 = 0;
        for (0..p.velocity.len)|i|{
            p.velocity[i]=p.velocity[i] 
                + p.cognitive_coef*(@as(f32,@floatFromInt(@as(i32,p.best_position[i]) - @as(i32,p.position[i])))) 
                + p.social_coef*(@as(f32,@floatFromInt(@as(i32,global_best[i]) - @as(i32,p.position[i]))));
            mag = mag + std.math.pow(f32, p.velocity[i], 2);
        }
        mag = @sqrt(mag);
        for (0..p.velocity.len)|i|{
            p.velocity[i]=p.velocity[i]/mag;
        }
    }

    // Constrained to move 1 at a time. Might need adjustment.
    pub fn move(p: *Particle) void{
        const movement_vector = generateMovementVector(&p.velocity);
        for (movement_vector, 0..) |val, i|{
            p.position[i] = @as(u8,@intCast(@as(i8,@intCast(p.position[i])) + val));
        }
        const is_valid = p.validate();
        if (!is_valid){p.fixPosition();}
    }

    pub fn print(p: *Particle, writer: anytype) !void{
        try writer.print("Position: ",.{});
        try printVector(p.position, writer);
        try writer.print("Velocity: ",.{});
        try printVector(p.velocity, writer);
        try writer.print("Best Pos: ",.{});
        try printVector(p.best_position, writer);
    }

    fn fixPosition(p: *Particle) void{
        var bits = std.StaticBitSet(52).initEmpty();
        var val: u8 =0;
        for (0..p.position.len) |i| {
            if (p.position[i] < 0 ){p.position[i] = 0;}
            if (p.position[i] > 51 ){p.position[i] = 51;}
            val = p.position[i];
            if (bits.isSet(val)){
                var replacement = @as(i8,@intCast(val));
                var dir = @as(i8,@intFromFloat(std.math.sign(p.velocity[i])));
                if (dir == 0){dir =1;}
                var hasSwappedDir = false;
                // std.debug.print("Find new position: {}, {}\n", .{val, dir});
                while (0 <= replacement and replacement < 52) : (replacement += dir){
                    // std.debug.print("Checking: {}, {}\n", .{replacement, dir});
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
                        for(p.position)|pval|{
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