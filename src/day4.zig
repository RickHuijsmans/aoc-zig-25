const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");
const List = @import("lib/list.zig").List;

const NeighbourIterator = struct {
    grid: *const Grid,
    x: usize,
    y: usize,
    pos: usize,

    pub fn init(grid: *const Grid, x: usize, y: usize) NeighbourIterator{
        return NeighbourIterator{
            .grid = grid,
            .x = x,
            .y = y,
            .pos = 0
        };
    }

    pub fn next(self: *NeighbourIterator) ?.{usize, usize} {
        while(self.pos < 9): (self.pos += 1){
            const rX = @rem(self.pos, 3);
            const rY = @divFloor(self.pos, 3);

            if((rX == 1 and rY == 1) or (rX == 0 and self.x == 0) or (rY == 0 and self.y == 0) or (rX == 2 and self.x == self.width - 1) or (rY == 2 and self.y == self.height - 1)){
                continue;
            }

            return .{self.x + rX - 1, self.y + rY - 1};
        }

        return null;
    }
};

const Grid = struct {
    string: String,
    width: usize,
    height: usize,

    pub fn init(allocator: std.mem.Allocator, input: *const String) !Grid{
        const width = getLineLength(input);
        const cleaned = try input.stringReplace(allocator, "\n", "");
        const height = cleaned.size / width;
        return Grid { .string = cleaned, .width = width, .height = height };
    }

    pub fn get(self: *const Grid, x: usize, y: usize) u8 {
        return self.getByIndex(self.getIndex(x,y));
    }

    pub fn getByIndex(self: *const Grid, index: usize) u8{
        return self.string.contents[index];
    }

    pub fn getPos(self: *const Grid, index: usize) struct{ usize, usize }{
        const y = @divFloor(index, self.width);
        const x = @mod(index, self.width);

        return .{x, y};
    }

    pub fn getIndex(self: *const Grid, x: usize, y: usize) usize {
        return y * self.height + x;
    }

    pub fn getRow(self: *const Grid, row: usize) []const u8 {
        const start = row * self.height;
        return self.string.contents[start..start + self.width];
    }

    pub fn getNeigbours(self: *const Grid, x: usize, y: usize) NeighbourIterator{
        return NeighbourIterator.init(self, x, y);
    }

    pub fn getNeighboursWith(self: *const Grid, x: usize, y: usize, search: u8) u8{
        var results: u8 = 0;

        inline for(0..3) |rX|{
            for(0..3) |rY| {
                if((rX == 1 and rY == 1) or (rX == 0 and x == 0) or (rY == 0 and y == 0) or (rX == 2 and x == self.width - 1) or (rY == 2 and y == self.height - 1)){
                    continue;
                }

                if(self.get(x + rX - 1, y + rY - 1) == search){
                    results += 1;
                }
            }
        }

        return results;
    }

    pub fn clone(self: *const Grid, allocator: std.mem.Allocator) !Grid{
        return Grid{
            .string = try self.string.clone(allocator),
            .width = self.width,
            .height = self.height
        };
    }

    fn getLineLength(input: *const String) usize {
        return @intCast(input.indexOf('\n'));
    }
};

pub const Day4 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day4, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day4, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day4 {
        return .{ .day = 4, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\..@@.@@@@.
        \\@@@.@.@.@@
        \\@@@@@.@.@@
        \\@.@@@@..@.
        \\@@.@@@@.@@
        \\.@@@@@@@.@
        \\.@.@.@.@@@
        \\@.@@@.@@@@
        \\.@@@@@@@@.
        \\@.@.@@@.@.
    );

    pub fn solveSample1(self: *const Day4) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(self: *const Day4, alloc: std.mem.Allocator, raw: *const String) !u64 {
        const grid = try Grid.init(alloc, raw);
        var rolls: u64 = 0;

        for(0..grid.string.size)|i|{
            const value = grid.getByIndex(i);
            const x, const y = grid.getPos(i);

            if(x == 0){
                self.debugLine("",.{});
            }

            if(value != '@'){
                self.debug("{s}",.{ [1]u8{value}});
                continue;
            }

            const neighbours = grid.getNeighboursWith(x, y, '@');
            if(neighbours < 4){
                self.debug("x", .{});
                rolls += 1;
            }else{
                self.debug("@", .{});
            }
        }

        return rolls;
    }

    pub fn solveSample2(self: *const Day4) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day4, alloc: std.mem.Allocator, raw: *const String) !u64 {
        var grid = try Grid.init(alloc, raw);
        var copy = try grid.clone(alloc);
        var stack = try List(usize).initCapacity(alloc, 1024);
        var rolls: u64 = 0;
        var prevRolls: u64 = 0;

        for(0..grid.string.size)|i|{
            const value = grid.getByIndex(i);
            const x, const y = grid.getPos(i);

            if(x == 0){
                self.debugLine("",.{});
            }

            if(value != '@'){
                self.debug("{s}",.{ [1]u8{value}});
                continue;
            }

            const neighbours = grid.getNeighboursWith(x, y, '@');
            if(neighbours < 4){
                self.debug("x", .{});
                rolls += 1;

                copy.string.contents[i] = 'x';
                try stack.add(i);
            }else{
                self.debug("@", .{});
            }
        }

        var tmp: Grid = undefined;
        while(rolls != prevRolls){
            tmp = grid;
            grid = copy;
            copy = tmp;

            // while(stack.count() > 0) {
            //     const i = stack.pop();
            // }



            prevRolls = rolls;
            stack.clear();
        }

        return rolls;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day4);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(13, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day4);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(1349, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day4);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(43, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day4);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(0, result);
}
