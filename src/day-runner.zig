const std = @import("std");
const inputHelper = @import("utility/input-helper.zig");

pub fn runDay(comptime n: u8, allocator: std.mem.Allocator) !void {
    var arena1 = std.heap.ArenaAllocator.init(allocator);
    var arena2 = std.heap.ArenaAllocator.init(allocator);
    defer arena1.deinit();
    defer arena2.deinit();

    // Update this to add new days
    var d = switch (n) {
        1 => @import("day1.zig").Day1.init(allocator, false),
        2 => @import("day2.zig").Day2.init(allocator, false),
        3 => @import("day3.zig").Day3.init(allocator, false),
        else => return,
    };

    var input = try inputHelper.getInput(allocator, n);
    defer input.deinit();

    // Part 1
    var memBefore = arena1.queryCapacity();
    var before = std.time.microTimestamp();

    var result = try d.solve1(arena1.allocator(), &input);

    var time: f64 = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    var usedMem = @as(f64, @floatFromInt(arena1.queryCapacity() - memBefore)) / 1024;

    std.debug.print("Day {d} - Part 1: {} in {} ms ({d:.2} Kb)\n", .{ n, result, time, usedMem });

    // Part 2
    memBefore = arena2.queryCapacity();
    before = std.time.microTimestamp();

    result = try d.solve2(arena2.allocator(), &input);

    time = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    usedMem = @as(f64, @floatFromInt(arena2.queryCapacity() - memBefore)) / 1024;

    std.debug.print("Day {d} - Part 2: {} in {} ms ({d:.2} Kb)\n", .{ n, result, time, usedMem });
}
