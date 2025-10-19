// Count set bits
const S = [_]u8{1, 2, 4, 8, 16, 32};
const B = [_]u64{
    0x5555555555555555,
    0x3333333333333333,
    0x0F0F0F0F0F0F0F0F,
    0x00FF00FF00FF00FF,
    0x0000FFFF0000FFFF,
    0x00000000FFFFFFFF,
};

pub const REVERSE_BYTE_TABLE = generateReverseByteTable();




pub fn countSetBits(v:u64)u64{
    var c = v - ((v >> 1) & B[0]);
    c = ((c >> S[1]) & B[1]) + (c & B[1]);
    c = ((c >> S[2]) + c) & B[2];
    c = ((c >> S[3]) + c) & B[3];
    c = ((c >> S[4]) + c) & B[4];
    c = ((c >> S[5]) + c) & B[5];
    return c;
}

pub fn reverseBitsLoop(T: type, v:T) T{
    var result: T = 0;
    var input: T = v;
    for (0..(@sizeOf(T)*8))|_|{
        result = (result << 1) | (input & 1);
        input >>=1;
    }
    return result;
}

pub fn reverseByte(b:u8) u8{
    return REVERSE_BYTE_TABLE[b];
}


fn generateReverseByteTable() [256]u8{
comptime{
    @setEvalBranchQuota(2561);
    var table:[256]u8 = undefined;
    for (0..256)|i|{
        table[i] = reverseBitsLoop(u8, @intCast(i));
    }
    return table;
}}