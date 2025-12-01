const std = @import("std");
const file = @import("lib/file.zig");
const aoc_zig_25 = @import("aoc_zig_25");
const Day1Old = @import("day1_old.zig").Day1;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var puzzle_input = try file.getInput(alloc);
    defer puzzle_input.deinit();

    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const day1 = Day1Old{ .allocator = arena.allocator(), .input = &puzzle_input };
    const memBefore = arena.queryCapacity();
    const before = std.time.microTimestamp();
    const solution1 = try day1.solvePart1();
    const time: f64 = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    const usedMem = @as(f64, @floatFromInt(arena.queryCapacity() - memBefore)) / 1024;

    std.debug.print("Day 1 - Part 1 (new): {} in {} ms ({d:.2} Kb)\n", .{ solution1, time, usedMem });

}
