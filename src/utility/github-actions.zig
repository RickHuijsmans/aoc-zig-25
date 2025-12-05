const std = @import("std");

pub const DayResult = struct {
    day: u8,
    part1: ResultData,
    part2: ResultData,
};

pub const ResultData = struct {
    result: u64,
    time_ms: f64,
    cycles: u64,
    memory_kb: f64,
};

const DayStats = struct {
    day: u8,
    time_ms: f64,
    memory_kb: f64,
};

pub const GithubActionsSummary = struct {
    file: ?std.fs.File,
    allocator: std.mem.Allocator,
    day_stats: [max_days]DayStats,
    stats_count: usize,

    const Self = @This();
    const max_days = 25;

    /// Initialize the summary writer. Returns a struct that safely no-ops
    /// if GITHUB_STEP_SUMMARY environment variable is not set.
    pub fn init(allocator: std.mem.Allocator) Self {
        const empty_stats = [_]DayStats{.{ .day = 0, .time_ms = 0, .memory_kb = 0 }} ** max_days;

        const path = std.process.getEnvVarOwned(allocator, "GITHUB_STEP_SUMMARY") catch {
            return Self{
                .file = null,
                .allocator = allocator,
                .day_stats = empty_stats,
                .stats_count = 0,
            };
        };
        defer allocator.free(path);

        // Try to open existing file first, then create if it doesn't exist
        const file = std.fs.openFileAbsolute(path, .{ .mode = .write_only }) catch |err| switch (err) {
            error.FileNotFound => std.fs.createFileAbsolute(path, .{}) catch {
                return Self{
                    .file = null,
                    .allocator = allocator,
                    .day_stats = empty_stats,
                    .stats_count = 0,
                };
            },
            else => return Self{
                .file = null,
                .allocator = allocator,
                .day_stats = empty_stats,
                .stats_count = 0,
            },
        };

        // Seek to end to append
        file.seekFromEnd(0) catch {
            file.close();
            return Self{
                .file = null,
                .allocator = allocator,
                .day_stats = empty_stats,
                .stats_count = 0,
            };
        };

        return Self{
            .file = file,
            .allocator = allocator,
            .day_stats = empty_stats,
            .stats_count = 0,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.file) |f| {
            f.close();
        }
        self.file = null;
    }

    /// Returns true if running inside GitHub Actions with summary support
    pub fn isAvailable(self: *const Self) bool {
        return self.file != null;
    }

    /// Write a raw string to the summary
    pub fn write(self: *Self, content: []const u8) void {
        const file = self.file orelse return;
        file.writeAll(content) catch {};
    }

    /// Write a formatted string to the summary
    pub fn print(self: *Self, comptime fmt: []const u8, args: anytype) void {
        const file = self.file orelse return;
        const formatted = std.fmt.allocPrint(self.allocator, fmt, args) catch return;
        defer self.allocator.free(formatted);
        file.writeAll(formatted) catch {};
    }

    /// Write a header to the summary
    pub fn writeHeader(self: *Self, comptime level: u8, text: []const u8) void {
        if (self.file == null) return;
        const prefix = switch (level) {
            1 => "# ",
            2 => "## ",
            3 => "### ",
            4 => "#### ",
            else => "##### ",
        };
        self.write(prefix);
        self.write(text);
        self.write("\n\n");
    }

    /// Write a single day's results to the summary
    pub fn writeDayResult(self: *Self, day: u8, part: u8, result: u64, time_ms: f64, cycles: u64, memory_kb: f64) void {
        if (self.file == null) return;
        self.print("**Day {d} - Part {d}:** `{d}` in {d:.3} ms / {d} cycles ({d:.2} KB)\n\n", .{
            day,
            part,
            result,
            time_ms,
            cycles,
            memory_kb,
        });
    }

    /// Begin a results table with headers
    pub fn beginResultsTable(self: *Self) void {
        if (self.file == null) return;
        self.write("| Day | Part | Result | Time (ms) | Cycles | Memory (KB) |\n");
        self.write("|-----|------|--------|-----------|--------|-------------|\n");
    }

    /// Add a row to the results table
    pub fn writeResultRow(self: *Self, day: u8, part: u8, result: u64, time_ms: f64, cycles: u64, memory_kb: f64) void {
        if (self.file == null) return;
        self.print("| {d} | {d} | `{d}` | {d:.3} | {d} | {d:.2} |\n", .{
            day,
            part,
            result,
            time_ms,
            cycles,
            memory_kb,
        });
    }

    /// Write a complete day result (both parts) as table rows
    pub fn writeDayResultRows(self: *Self, day_result: DayResult) void {
        self.writeResultRow(
            day_result.day,
            1,
            day_result.part1.result,
            day_result.part1.time_ms,
            day_result.part1.cycles,
            day_result.part1.memory_kb,
        );
        self.writeResultRow(
            day_result.day,
            2,
            day_result.part2.result,
            day_result.part2.time_ms,
            day_result.part2.cycles,
            day_result.part2.memory_kb,
        );
    }

    /// Write a newline
    pub fn newline(self: *Self) void {
        self.write("\n");
    }

    /// Record stats for a day (combines part 1 and part 2)
    /// Call this after both parts of a day have been solved
    pub fn recordDayStats(self: *Self, day: u8, part1_time_ms: f64, part1_memory_kb: f64, part2_time_ms: f64, part2_memory_kb: f64) void {
        if (self.stats_count >= max_days) return;
        self.day_stats[self.stats_count] = .{
            .day = day,
            .time_ms = part1_time_ms + part2_time_ms,
            .memory_kb = part1_memory_kb + part2_memory_kb,
        };
        self.stats_count += 1;
    }

    /// Write Mermaid Sankey diagrams showing time and memory distribution across days
    pub fn writeSankeyDiagrams(self: *Self) void {
        if (self.file == null) return;
        if (self.stats_count == 0) return;

        // Time distribution
        self.write("\n## Time Distribution\n\n");
        self.write("```mermaid\n");
        self.write("sankey-beta\n\n");

        for (self.day_stats[0..self.stats_count]) |stats| {
            self.print("Total time,Day {d},{d:.3}\n", .{ stats.day, stats.time_ms });
        }

        self.write("```\n");

        // Memory distribution
        self.write("\n## Memory Distribution\n\n");
        self.write("```mermaid\n");
        self.write("sankey-beta\n\n");

        for (self.day_stats[0..self.stats_count]) |stats| {
            self.print("Total memory,Day {d},{d:.2}\n", .{ stats.day, stats.memory_kb });
        }

        self.write("```\n");
    }
};
