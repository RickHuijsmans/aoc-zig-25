const std = @import("std");
const String = @import("lib/string.zig").String;

pub const PuzzleResult = struct {
    isCorrect: bool,
    value: String,
    timeElapsed: u64,
    memoryUsed: u64
};

pub const Day = struct {
    solvePart1: fn(allocator: std.mem.Allocator, input: String) anyerror!PuzzleResult,
    solvePart2: fn(allocator: std.mem.Allocator, input: String) anyerror!PuzzleResult
};
