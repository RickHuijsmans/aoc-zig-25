const std = @import("std");
const String = @import("lib/string.zig").String;

pub const PuzzleResult = struct { isCorrect: bool, timeElapsed: f64, memoryUsed: f64 };

pub const Day = struct {
    day: u8,
    input: String,
    solvePart1: fn () anyerror!PuzzleResult,
    solvePart2: fn () anyerror!PuzzleResult,
};
