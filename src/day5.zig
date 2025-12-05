const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");
const List = @import("lib/list.zig").List;

pub const Day5 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day5, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day5, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day5 {
        return .{ .day = 5, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\3-5
        \\10-14
        \\16-20
        \\12-18
        \\
        \\1
        \\5
        \\8
        \\11
        \\17
        \\32
    );

    pub fn solveSample1(self: *const Day5) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    const Range = struct {
        lower: u64,
        upper: u64,

        pub fn contains(self: *const Range, value: u64) bool {
            return value >= self.lower and value <= self.upper;
        }

        pub fn overlaps(self: *const Range, other: *const Range) bool {
            return (self.upper >= (other.lower - 1) and self.lower <= other.lower) or (other.upper >= (self.lower - 1) and other.lower <= self.lower);
        }

        pub fn within(self: *const Range, other: *const Range) bool {
            return other.lower >= self.lower and other.upper <= self.upper;
        }
    };

    pub fn solve1(self: *const Day5, alloc: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", false);
        var readingRanges = true;
        var ranges = try List(*Range).init(alloc);
        var ingredients = try List(u64).init(alloc);

        while (rows.next()) |row| {
            if (String.isNullOrWhitespace(row)) {
                if (!readingRanges) {
                    break;
                } else {
                    readingRanges = false;
                    continue;
                }
            }

            if (readingRanges) {
                const separatorIndex = String.indexOf(row, '-');
                const lower = try String.parseInt(row[0..@intCast(separatorIndex)], u64);
                const upper = try String.parseInt(row[@intCast(separatorIndex + 1)..], u64);

                var range = try alloc.create(Range);
                range.lower = lower;
                range.upper = upper;

                try ranges.add(range);

                self.debugLine("Parsed range: {}-{}", .{ lower, upper });
            } else {
                try ingredients.add(try String.parseInt(row, u64));
            }
        }

        try ranges.sort(struct {
            pub fn sort(_: void, range1: *Range, range2: *Range) bool {
                return range1.lower < range2.lower;
            }
        }.sort);

        var lastRange: ?*Range = null;
        var i: usize = 0;
        var newRanges = try List(*Range).initWithHashSet(alloc, @intCast(ranges.count()));

        while (i < ranges.count()) : (i += 1) {
            var range = ranges.get(i);
            if (lastRange) |last| {
                if (last.overlaps(range)) {
                    if (last.upper < range.upper) {
                        last.upper = range.upper;
                    }

                    if (last.lower > range.lower) {
                        last.lower = range.lower;
                    }

                    // _ = ranges.remove(range);
                    range = last;
                    // i -= 1;

                    ranges.set(i, range);
                } else {
                    try newRanges.add(range);
                }
            } else {
                try newRanges.add(range);
            }

            lastRange = range;
        }

        var freshIngredients: u64 = 0;
        var ingredientIterator = ingredients.iterator();
        while (ingredientIterator.next()) |ingredient| {
            for (0..newRanges.count()) |j| {
                if (newRanges.get(j).contains(ingredient)) {
                    freshIngredients += 1;
                    break;
                }
            }
        }

        return freshIngredients;
    }

    pub fn solveSample2(self: *const Day5) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day5, alloc: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", false);
        var ranges = try List(*Range).init(alloc);

        while (rows.next()) |row| {
            if (String.isNullOrWhitespace(row)) {
                break;
            }

            const separatorIndex = String.indexOf(row, '-');
            const lower = try String.parseInt(row[0..@intCast(separatorIndex)], u64);
            const upper = try String.parseInt(row[@intCast(separatorIndex + 1)..], u64);

            var range = try alloc.create(Range);
            range.lower = lower;
            range.upper = upper;

            try ranges.add(range);

            self.debugLine("Parsed range: {}-{}", .{ lower, upper });
        }

        try ranges.sort(struct {
            pub fn sort(_: void, range1: *Range, range2: *Range) bool {
                return range1.lower < range2.lower;
            }
        }.sort);

        var lastRange: ?*Range = null;
        var i: usize = 0;
        var newRanges = try List(*Range).initWithHashSet(alloc, @intCast(ranges.count()));

        while (i < ranges.count()) : (i += 1) {
            var range = ranges.get(i);
            if (lastRange) |last| {
                if (last.overlaps(range)) {
                    if (last.upper < range.upper) {
                        last.upper = range.upper;
                    }

                    if (last.lower > range.lower) {
                        last.lower = range.lower;
                    }

                    range = last;
                    ranges.set(i, range);
                } else {
                    try newRanges.add(range);
                }
            } else {
                try newRanges.add(range);
            }

            lastRange = range;
        }

        var freshIngredients: u64 = 0;
        var rangeIterator = newRanges.iterator();
        while (rangeIterator.next()) |range| {
            freshIngredients += range.upper - range.lower + 1;
        }

        return freshIngredients;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day5);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(3, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day5);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(862, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day5);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(14, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day5);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(357907198933892, result);
}
