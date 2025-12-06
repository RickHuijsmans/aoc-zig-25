const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");
const List = @import("lib/list.zig").List;

pub const Day6 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day6, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day6, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day6 {
        return .{ .day = 6, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    );

    pub fn solveSample1(self: *const Day6) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(self: *const Day6, alloc: std.mem.Allocator, input: *const String) !u64 {
        var solution: u64 = 0;
        var lines = try input.split("\n", true, alloc);

        const operatorLine = lines.last();
        const valueLines = lines.items.items[0 .. lines.count() - 1];

        var operatorStart: usize = 0;
        for (0..operatorLine.size) |ind| {
            var i = ind;
            const char = operatorLine.contents[i];
            if (String.isWhitespace(char) and i != operatorLine.size - 1) {
                continue;
            }

            if (i == operatorLine.size - 1) {
                i = operatorLine.size;
            }

            if (i > 0) {
                const operator = operatorLine.contents[operatorStart];
                var value: u64 = 0;

                self.debugLine("", .{});

                for (0..valueLines.len) |v| {
                    const digit = valueLines[v].contents[operatorStart .. i - 1];
                    const trimmed = std.mem.trim(u8, digit, " ");
                    if (trimmed.len == 0) {
                        continue;
                    }

                    const num = try String.parseInt(trimmed, u64);

                    if (v == valueLines.len - 1) {
                        self.debug("{}", .{num});
                    } else {
                        self.debug("{} {s} ", .{ num, [_]u8{operator} });
                    }

                    if (v == 0) {
                        value = num;
                    } else {
                        switch (operator) {
                            '*' => value *= num,
                            '+' => value += num,
                            else => @panic("Not implemented"),
                        }
                    }
                }

                solution += value;
                self.debug(" = {}", .{value});
            }

            operatorStart = i;
        }

        self.debugLine("", .{});
        return solution;
    }

    pub fn solveSample2(self: *const Day6) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day6, alloc: std.mem.Allocator, input: *const String) !u64 {
        var solution: u64 = 0;
        var lines = try input.split("\n", true, alloc);

        const operatorLine = lines.last();
        const valueLines = lines.items.items[0 .. lines.count() - 1];

        var operatorStart: usize = 0;
        for (0..operatorLine.size) |ind| {
            var i = ind;
            const char = operatorLine.contents[i];
            if (String.isWhitespace(char) and i != operatorLine.size - 1) {
                continue;
            }

            if (i == operatorLine.size - 1) {
                i = operatorLine.size;
            }

            if (i > 0) {
                const operator = operatorLine.contents[operatorStart];
                var value: u64 = 0;

                self.debugLine("", .{});
                for (operatorStart..i - 1) |j| {
                    const digit = try alloc.alloc(u8, valueLines.len);

                    for (0..valueLines.len) |v| {
                        const valueChar = valueLines[v].contents[j];
                        if (String.isDigit(valueChar)) {
                            digit[v] = valueChar;
                        } else {
                            digit[v] = ' ';
                        }
                    }

                    const trimmed = std.mem.trim(u8, digit, " ");
                    if (trimmed.len == 0) {
                        continue;
                    }

                    const num = try String.parseInt(trimmed, u64);

                    if (j == i - 2) {
                        self.debug("{}", .{num});
                    } else {
                        self.debug("{} {s} ", .{ num, [_]u8{operator} });
                    }

                    if (j == operatorStart) {
                        value = num;
                    } else {
                        switch (operator) {
                            '*' => value *= num,
                            '+' => value += num,
                            else => @panic("Not implemented"),
                        }
                    }
                }

                solution += value;
                self.debug(" = {}", .{value});
            }

            operatorStart = i;
        }

        self.debugLine("", .{});
        return solution;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day6);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(4277556, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day6);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(4693159084994, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day6);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(3263827, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day6);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(11643736116335, result);
}
