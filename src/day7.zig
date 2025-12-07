const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");
const List = @import("lib/list.zig").List;

pub const Day7 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day7, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day7, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day7 {
        return .{ .day = 7, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\.......S.......
        \\...............
        \\.......^.......
        \\...............
        \\......^.^......
        \\...............
        \\.....^.^.^.....
        \\...............
        \\....^.^...^....
        \\...............
        \\...^.^...^.^...
        \\...............
        \\..^...^.....^..
        \\...............
        \\.^.^.^.^.^...^.
        \\............... 
    );

    pub fn solveSample1(self: *const Day7) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(self: *const Day7, alloc: std.mem.Allocator, input: *const String) !u64 {
        var lines = try input.split("\n", true, alloc);
        const startPos = lines.first().indexOf('S').?;
        const beams = try alloc.alloc(bool, lines.first().size);
        beams[startPos] = true;

        const nextBeams = try alloc.dupe(bool, beams);
        var splits: u64 = 0;

        self.debug("\n", .{});
        for (1..lines.count()) |i| {
            const row = lines.get(i);
            for (0..beams.len) |b| {
                const char = row.contents[b];
                if (!beams[b]) {
                    self.debug("{s}", .{[_]u8{char}});
                    continue;
                }

                if (char == '^') {
                    self.debug("^", .{});
                    splits += 1;
                    nextBeams[b] = false;
                    if (b > 0) {
                        nextBeams[b - 1] = true;
                    }
                    if (b < lines.count() - 1) {
                        nextBeams[b + 1] = true;
                    }
                } else {
                    self.debug("|", .{});
                    nextBeams[b] = true;
                }
            }
            self.debug("\n", .{});

            std.mem.copyForwards(bool, beams, nextBeams);
        }

        return splits;
    }

    pub fn solveSample2(self: *const Day7) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day7, alloc: std.mem.Allocator, input: *const String) !u64 {
        var lines = try input.split("\n", true, alloc);
        const startPos = lines.first().indexOf('S').?;
        const beams = try alloc.alloc(u64, lines.first().size);
        @memset(beams, 0);
        const nextBeams = try alloc.dupe(u64, beams);
        beams[startPos] = 1;

        const print = (struct {
            pub fn printBeams(s: *const Day7, b: []u64) void {
                s.debugLine("", .{});

                for (0..b.len) |i| {
                    s.debug("{}", .{b[i]});
                }
                s.debugLine("", .{});
            }
        }.printBeams);

        print(self, beams);

        self.debug("\n", .{});
        for (1..lines.count()) |i| {
            const row = lines.get(i);
            for (0..beams.len) |b| {
                const char = row.contents[b];
                const value = beams[b];
                if (char == '^') {
                    self.debug("^", .{});
                    nextBeams[b] = 0;
                    if (b > 0) {
                        nextBeams[b - 1] += value;
                    }
                    if (b < lines.count() - 1) {
                        nextBeams[b + 1] += value;
                    }
                } else {
                    if (beams[b] == 0) {
                        self.debug(".", .{});
                    } else {
                        self.debug("|", .{});
                    }

                    nextBeams[b] += value;
                }
            }
            self.debug("\n", .{});
            std.mem.copyForwards(u64, beams, nextBeams);
            @memset(nextBeams, 0);
            print(self, beams);
        }

        var paths: u64 = 0;
        for (0..beams.len) |i| {
            paths += beams[i];
        }

        return paths;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day7);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(21, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day7);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(1662, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day7);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(40, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day7);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(40941112789504, result);
}
