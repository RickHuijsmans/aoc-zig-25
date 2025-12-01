const std = @import("std");
const String = @import("lib/string.zig").String;
const day = @import("day.zig");
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");

const Day1Impl = struct {
    allocator: std.mem.Allocator,

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

    pub fn solveSample1(self: *const Day1Impl) !u64 {
        return self.solve1(&sample1);
    }

    pub fn solve1(_: *const Day1Impl, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        const totalDigits: i16 = 100;
        const startPos: i16 = 50;
        var currentPos = startPos;
        var seenZeros: u64 = 0;

        std.debug.print("\nStart position: {}\n", .{startPos});

        while (rows.next()) |row| {
            const clockwise = row[0] == 'R';
            const amount = try String.parseInt(row[1..], i16);
            std.debug.print("Move {s} {} times\n", .{ row[0..1], amount });

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

            // std.debug.print("New Position: {}\n", .{currentPos});
        }

        return seenZeros;
    }

    pub fn solveSample2(self: *const Day1Impl) !u64 {
        return self.solve2(&sample1);
    }

    pub fn solve2(_: *const Day1Impl, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        const totalDigits: i16 = 100;
        const startPos: i16 = 50;
        var currentPos = startPos;
        var seenZeros: u64 = 0;

        std.debug.print("\nStart position: {}\n", .{startPos});

        while (rows.next()) |row| {
            const clockwise = row[0] == 'R';
            const amount = try String.parseInt(row[1..], i16);
            const startZeros = seenZeros;
            const prevPos = currentPos;

            std.debug.print("Move {s} {} times", .{ row[0..1], amount });

            for (0..@intCast(amount)) |_| {
                currentPos += if (clockwise) 1 else -1;
                currentPos = @mod(currentPos, totalDigits);

                if (currentPos == 0) {
                    seenZeros += 1;
                }
            }

            std.debug.print("\n", .{});
            if (seenZeros != startZeros) {
                std.debug.print("Position: {} -> {} with {} zeroes\n\n", .{ prevPos, currentPos, seenZeros - startZeros });
            } else {
                std.debug.print("Position: {} => {}\n\n", .{ prevPos, currentPos });
            }
        }

        return seenZeros;
    }
};

test "Sample 1" {
    const pageAlloc = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(pageAlloc);
    const alloc = arena.allocator();
    const context = Day1Impl{ .allocator = alloc };
    const result = try context.solveSample1();
    try std.testing.expectEqual(3, result);
}

test "Solve 1" {
    const pageAlloc = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(pageAlloc);
    const alloc = arena.allocator();
    const context = Day1Impl{ .allocator = alloc };

    const input = try file.getInput(alloc, "./src/day1.input");
    const result = try context.solve1(&input);
    try std.testing.expectEqual(982, result);
}

test "Sample 2" {
    const pageAlloc = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(pageAlloc);
    const alloc = arena.allocator();
    const context = Day1Impl{ .allocator = alloc };
    const result = try context.solveSample2();
    try std.testing.expectEqual(6, result);
}

test "Solve 2" {
    const pageAlloc = std.heap.page_allocator;
    var arena = std.heap.ArenaAllocator.init(pageAlloc);
    const alloc = arena.allocator();
    const context = Day1Impl{ .allocator = alloc };

    const input = try file.getInput(alloc, "./src/day1.input");
    const result = try context.solve2(&input);
    try std.testing.expectEqual(6106, result);
}
