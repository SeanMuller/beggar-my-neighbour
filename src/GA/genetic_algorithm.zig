const std = @import("std");
const gene = @import("genome.zig");
const gs = @import("../Games/First Attempt/game_state.zig");

const SIZE:usize = 1000;
const GENERATIONS:usize = 1000;
const GOAL:usize = 4792;

pub const Population = struct{
    pop: [2][SIZE]gene.Genome = undefined,
    act_gen:u1 = 0,
    gen:u64 = 0,
    best_position:[16]u8 = undefined,
    best_score: u64 = 0,
    total_fitness: u64 =0,
    game: gs.GameState = undefined,
    mutation_rate: f32 = 0.2,
    hashMap: std.AutoHashMap(gene.Genome, u64) = undefined,

    pub fn init(p: *Population) void{
        p.game.init();
        p.act_gen = 0;
        p.gen = 0;
        p.pop[0] =  [_]gene.Genome{.{}} ** SIZE;
        p.pop[1] =  [_]gene.Genome{.{}} ** SIZE;
        for (0..SIZE)|i|{
            p.pop[p.act_gen][i].init();
        }
    }

    pub fn runEvolution(p: *Population) !void{
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        const allocator = gpa.allocator();

        p.hashMap = std.hash_map.AutoHashMap(gene.Genome, u64).init(allocator);
        defer p.hashMap.deinit();

        const now = std.time.timestamp();
        const filename = try std.fmt.allocPrint(
            allocator, 
            "logs/ga/{}-{}-{}.txt",
            .{SIZE, GENERATIONS, now}
        );
        defer allocator.free(filename);
        const file = try std.fs.cwd().createFile(filename, .{.truncate=true});
        defer file.close();

        while (p.best_score < GOAL and p.gen < GENERATIONS): (p.gen+=1){
            const old_score = p.best_score;
            try p.evaluate();
            p.reproduce();
            if (old_score != p.best_score or p.gen % (GENERATIONS/10) == 0){
                try file.writer().print(
                    "{}, {}, {s}\n",
                    .{p.gen, p.best_score, gene.posToString(p.best_position)}
                );
            }
        }
    }

    pub fn playBestGame(p: *Population, writer: anytype) !void{
        p.game.starting_deck.stack = convertToDeckStack(&p.best_position);
        p.game.reset();
        try p.game.print(writer);
        p.game.playGame();
        try p.game.print(writer);
    }

    fn evaluate(p: *Population) !void{
        p.total_fitness = 0;
        for(0..SIZE)|i|{
            // Don't evaluate an already evaluated position
            if (p.hashMap.get(p.pop[p.act_gen][i])) |fitness|{
                p.pop[p.act_gen][i].fitness = fitness;
                continue;
            }
            p.game.starting_deck.stack = convertToDeckStack(&p.pop[p.act_gen][i].dna);
            p.game.reset();
            p.game.playGame();
            p.pop[p.act_gen][i].fitness = p.game.turn;
            p.total_fitness += p.game.turn;
            try p.hashMap.put(p.pop[p.act_gen][i], p.pop[p.act_gen][i].fitness);
            if (p.game.turn > p.best_score){
                p.best_score = p.game.turn;
                p.best_position = p.pop[p.act_gen][i].dna;
            }
        }
    }

    fn reproduce(p: *Population) void{
        const rand = std.crypto.random;
        p.pop[~p.act_gen][0].dna = p.best_position;
        // Repopulate
        for (1..SIZE) |i|{
            const father = rand.uintLessThan(u64, p.total_fitness);
            const mother = rand.uintLessThan(u64, p.total_fitness);
            const gene_mix: u16 = rand.uintAtMost(u16, 0xFFFF);
            var parents:[2][16]u8 = undefined;
            var counter:u64 =0;
            // Select parents
            for (0..SIZE) |j|{
                counter += p.pop[p.act_gen][j].fitness;
                if (counter >= father){
                    parents[0]=p.pop[p.act_gen][j].dna;
                }
                if (counter >= mother){
                    parents[1]=p.pop[p.act_gen][j].dna;
                }
            }
            // Mix genes
            p.pop[~p.act_gen][i].fitness = 0;
            for (0..16) |j|{
                const gene_parent = gene_mix>>@as(u4,@intCast(j)) & 0x1;
                p.pop[~p.act_gen][i].dna[j] = parents[gene_parent][j];
            }
            p.pop[~p.act_gen][i].fixDNA();
            //Mutate
            p.pop[~p.act_gen][i].mutate(p.mutation_rate);
        }
        p.act_gen = ~p.act_gen;
    }

    fn convertToDeckStack(p: *[16]u8) [52]u4{
        var starting_deck = [_]u4{0} ** 52;
        for (p, 0..)|val, i|{
            starting_deck[val] = @as(u4,@intCast(i/4 + 1));
        }
        return starting_deck;
    }
};