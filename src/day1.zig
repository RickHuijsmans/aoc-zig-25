const std = @import("std");
const String = @import("lib/string.zig").String;
const day = @import("day.zig");
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");

pub const Day1 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day1, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day1 {
        return .{ .day = 1, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    );

    pub fn solveSample1(self: *const Day1) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(self: *const Day1, _: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        const totalDigits: i16 = 100;
        const startPos: i16 = 50;
        var currentPos = startPos;
        var seenZeros: u64 = 0;

        self.debug("\nStart position: {}\n", .{startPos});

        while (rows.next()) |row| {
            const clockwise = row[0] == 'R';
            const amount = try String.parseInt(row[1..], i16);
            self.debug("Move {s} {} times\n", .{ row[0..1], amount });

            if (clockwise) {
                currentPos += amount;
            } else {
                currentPos -= amount;
                while (currentPos < 0) {
                    currentPos = totalDigits + currentPos;
                }
            }

            currentPos = @mod(currentPos, totalDigits);
            if (currentPos == 0) {
                seenZeros += 1;
            }
        }

        return seenZeros;
    }

    pub fn solveSample2(self: *const Day1) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day1, _: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        const totalDigits: i16 = 100;
        const startPos: i16 = 50;
        var currentPos = startPos;
        var seenZeros: u64 = 0;

        self.debug("\nStart position: {}\n", .{startPos});

        while (rows.next()) |row| {
            const clockwise = row[0] == 'R';
            const amount = try String.parseInt(row[1..], i16);
            const startZeros = seenZeros;
            const prevPos = currentPos;

            self.debug("Move {s} {} times", .{ row[0..1], amount });

            for (0..@intCast(amount)) |_| {
                currentPos += if (clockwise) 1 else -1;
                currentPos = @mod(currentPos, totalDigits);

                if (currentPos == 0) {
                    seenZeros += 1;
                }
            }

            self.debug("\n", .{});
            if (seenZeros != startZeros) {
                self.debug("Position: {} -> {} with {} zeroes\n\n", .{ prevPos, currentPos, seenZeros - startZeros });
            } else {
                self.debug("Position: {} => {}\n\n", .{ prevPos, currentPos });
            }
        }

        return seenZeros;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day1);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(3, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day1);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(982, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day1);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(6, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day1);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(6106, result);
}
