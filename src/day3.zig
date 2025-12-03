const std = @import("std");
const String = @import("lib/string.zig").String;
const day = @import("day.zig");
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");

pub const Day3 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    const powLookup = utility.getPowLookup(u64, 12);

    pub fn debug(self: *const Day3, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day3 {
        return .{ .day = 3, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\987654321111111
        \\811111111111119
        \\234234234234278
        \\818181911112111
    );

    pub fn solveSample1(self: *const Day3) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(_: *const Day3, _: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        var joltage: u64 = 0;

        while (rows.next()) |row| {
            joltage += optimize(&row, 2);
        }

        return joltage;
    }

    pub fn solveSample2(self: *const Day3) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(_: *const Day3, _: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        var joltage: u64 = 0;

        while (rows.next()) |row| {
            joltage += optimize(&row, 12);
        }

        return joltage;
    }

    fn optimize(batteryBank: *const []const u8, digits: usize) u64 {
        var cellsRemaining: usize = digits;
        var total: u64 = 0;
        var start: usize = 0;
        while (cellsRemaining > 0) {
            var highest: usize = 0;
            var highestIndex: usize = 0;

            for (start..batteryBank.len - cellsRemaining + 1) |i| {
                const value = batteryBank.*[i] - 48;
                if (value > highest) {
                    highest = value;
                    highestIndex = i;
                }
            }

            total += powLookup[cellsRemaining - 1] * highest;
            start = highestIndex + 1;
            cellsRemaining -= 1;
        }
        return total;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day3);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(357, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day3);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(17281, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day3);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(3121910778619, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day3);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(171388730430281, result);
}
