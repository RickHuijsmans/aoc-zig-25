const std = @import("std");
const aoc_zig_25 = @import("aoc_zig_25");
const dayRunner = @import("day-runner.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    comptime var day: u8 = 0;
    inline while (day < 12) : (day += 1) {
        try dayRunner.runDay(day, alloc);
    }
}
