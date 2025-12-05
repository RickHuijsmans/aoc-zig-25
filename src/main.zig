const std = @import("std");
const aoc_zig_25 = @import("aoc_zig_25");
const dayRunner = @import("day-runner.zig");
const ghActions = @import("utility/github-actions.zig");
const days = @import("days.zig");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var summary = ghActions.GithubActionsSummary.init(alloc);
    defer summary.deinit();

    summary.writeHeader(1, "Advent of Code 2025 - Zig Solutions");
    summary.beginResultsTable();

    inline for (days.implemented_days) |day| {
        try dayRunner.runDay(day, alloc, &summary);
    }

    summary.writeSankeyDiagrams();
}
