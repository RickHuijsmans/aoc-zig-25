const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");

pub const Day2 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day2, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day2, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day2 {
        return .{ .day = 2, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
    );

    pub fn solveSample1(self: *const Day2) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(self: *const Day2, alloc: std.mem.Allocator, input: *const String) !u64 {
        var invalids: u64 = 0;
        var sanitized = try input.trimWhitespace(alloc);
        var checks: u64 = 0;
        var passes: u64 = 0;
        defer sanitized.deinit();

        const powLookup = utility.getPowLookup(u64, 6);
        var pairs = try linq.split(sanitized, ",", true);
        while (pairs.next()) |pair| {
            var segments = try linq.split(pair, "-", true);
            const s1 = segments.next().?;
            const s2 = segments.next().?;

            const start = try String.parseInt(s1, u64);
            const startDigits = utility.getDigits(u64, start);

            const end = try String.parseInt(s2, u64);
            const endDigits = utility.getDigits(u64, end);

            self.debugLine("Range: {s}-{s}", .{ s1, s2 });
            for (startDigits..endDigits + 1) |digit| {
                if (digit % 2 == 1)
                    continue;

                const halfDigit = digit / 2;
                const half = powLookup[halfDigit];

                const first = @divFloor(@as(u64, @intCast(start)), half);
                var last = @divFloor(@as(u64, @intCast(end)), half);
                if (last >= half)
                    last = half;

                self.debugLine("Digit: {}", .{digit});
                self.debugLine("First: {}, Last: {} ({})", .{ first, last, half });

                for (first..last + 1) |i| {
                    const value = i + half * i;
                    checks += 1;
                    if (value >= start and value <= end and utility.getDigits(u64, value) == digit) {
                        self.debugLine("Digit: {} ({} + {})", .{ value, half * i, i });
                        invalids += value;
                        passes += 1;
                    }
                }
            }

            self.debug("\nChecks: {}/{}\n", .{ passes, checks });
            passes = 0;
            checks = 0;
        }

        return invalids;
    }

    pub fn solveSample2(self: *const Day2) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day2, alloc: std.mem.Allocator, input: *const String) !u64 {
        var invalids: u64 = 0;
        var checks: u64 = 0;
        var passes: u64 = 0;
        var sanitized = try input.trimWhitespace(alloc);
        defer sanitized.deinit();

        var pairs = try linq.split(sanitized, ",", true);
        var skips: u64 = 0;

        const powLookup = utility.getPowLookup(usize, 6);
        while (pairs.next()) |pair| {
            var segments = try linq.split(pair, "-", true);
            const s1 = segments.next().?;
            const s2 = segments.next().?;

            const start = try String.parseInt(s1, u64);
            const end = try String.parseInt(s2, u64);
            for (start..end + 1) |i| {
                var isMatch = false;

                const digits = utility.getDigits(usize, i);
                if (digits < 2) {
                    skips += 1;
                    continue;
                }

                for (1..digits / 2 + 1) |digit| {
                    if (@rem(digits, digit) != 0) {
                        skips += 1;
                        continue;
                    }

                    var subMatch = true;
                    const pow = powLookup[digit];
                    const pattern = i % pow;
                    checks += 1;

                    var val = @divFloor(i, pow);
                    while (val > 0 and subMatch) : (val = @divFloor(val, pow)) {
                        subMatch = subMatch and pattern == val % pow;
                    }

                    if (subMatch) {
                        isMatch = true;
                        passes += 1;
                        break;
                    }
                }

                if (isMatch) {
                    invalids += i;
                    self.debug("\nAdding {d}", .{i});
                }
            }

            self.debug("\nChecks: {}/{}\n", .{ passes, checks });
            passes = 0;
            checks = 0;
        }

        self.debug("\nSkips: {}\n", .{skips});

        return invalids;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day2);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(1227775554, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day2);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(52316131093, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day2);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(4174379265, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day2);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(69564213293, result);
}
