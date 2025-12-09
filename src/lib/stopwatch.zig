const std = @import("std");

pub const Stopwatch = struct {
    time: i64,

    pub fn init() Stopwatch {
        return Stopwatch{ .time = getTime() };
    }

    pub fn start(self: *Stopwatch) void {
        self.time = getTime();
    }

    pub fn restart(self: *Stopwatch) i64 {
        const now = getTime();
        const duration = now - self.time;
        self.time = now;
        return duration;
    }

    pub fn report(self: *Stopwatch, comptime fmt: []const u8) void {
        const time = self.restart();
        std.debug.print(fmt ++ ": {} ms\n", .{@divFloor(@as(f64, @floatFromInt(time)), 1024)});
    }

    fn getTime() i64 {
        return std.time.microTimestamp();
    }
};
