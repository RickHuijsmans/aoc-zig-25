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

    const Problem = struct {
        operators: List(u8),
        rows: List(List(u64)),

        pub fn init1(alloc: std.mem.Allocator, input: *const String) !Problem {
            var rows = try List(List(u64)).init(alloc);
            var lines = try linq.split(input, "\n", true);
            var operators = try List(u8).init(alloc);

            while (lines.next()) |line| {
                var lastChar: ?usize = null;
                var firstChar: ?usize = null;
                var row = try List(u64).init(alloc);

                for (0..line.len) |i| {
                    const char = line[i];
                    if (String.isWhitespace(char)) {
                        if (lastChar != null and i - lastChar.? == 1) {
                            const slice = line[firstChar.? .. lastChar.? + 1];

                            if (slice.len == 1 and !String.isDigit(slice[0])) {
                                try operators.add(slice[0]);
                            } else {
                                try row.add(try String.parseInt(slice, u64));
                            }
                        }
                    } else {
                        if (firstChar == null or i - lastChar.? > 1) {
                            firstChar = i;
                        }

                        lastChar = i;
                    }
                }

                if (lastChar != null and line.len - lastChar.? == 1) {
                    const slice = line[firstChar.? .. lastChar.? + 1];

                    if (slice.len == 1 and !String.isDigit(slice[0])) {
                        try operators.add(slice[0]);
                    } else {
                        try row.add(try String.parseInt(slice, u64));
                    }
                }

                if (row.count() >= 1) {
                    try rows.add(row);
                } else {
                    row.deinit();
                }
            }

            return Problem{ .operators = operators, .rows = rows };
        }

        pub fn count(self: *const Problem) usize {
            return self.operators.count();
        }

        pub fn solve(self: *const Problem, index: usize) u64 {
            var value: u64 = 0;
            const operator = self.operators.get(index);
            for (0..self.rows.count()) |r| {
                const val = self.rows.get(r).get(index);
                if (r == 0) {
                    value = val;
                    continue;
                }

                switch (operator) {
                    '*' => value = value * val,
                    '+' => value += val,
                    else => @panic("Not implemented"),
                }
            }
            return value;
        }

        pub fn print(self: *const Problem) void {
            std.debug.print("\n", .{});
            for (0..self.operators.count()) |i| {
                for (0..self.rows.count()) |r| {
                    const val = self.rows.get(r).get(i);

                    if (r < self.rows.count() - 1) {
                        std.debug.print("{} {s} ", .{ val, [_]u8{self.operators.get(i)} });
                    } else {
                        std.debug.print("{}", .{val});
                    }
                }

                std.debug.print("\n", .{});
            }
        }
    };

    const sample1 = String.initFixed(
        \\123 328  51 64 
        \\ 45 64  387 23 
        \\  6 98  215 314
        \\*   +   *   +  
    );

    pub fn solveSample1(self: *const Day6) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(_: *const Day6, alloc: std.mem.Allocator, input: *const String) !u64 {
        const problem = try Problem.init1(alloc, input);
        problem.print();

        var solution: u64 = 0;
        for (0..problem.count()) |i| {
            solution += problem.solve(i);
        }

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
