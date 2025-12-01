const std = @import("std");
const String = @import("../lib/string.zig").String;
const inputHelper = @import("input-helper.zig");

pub fn TestEnvironment(comptime T: type) type {
    return struct {
        day: T,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn dayNr(self: *const Self) u8 {
            return self.day.day;
        }

        pub fn getInput(self: *const Self) !String {
            return inputHelper.getInput(self.allocator, self.dayNr());
        }
    };
}

pub fn initTest(comptime T: type) TestEnvironment(T) {
    const pageAlloc = std.heap.page_allocator;
    const instance = T.init(pageAlloc, true);
    return TestEnvironment(T){ .day = instance, .allocator = pageAlloc };
}

pub fn printDebug(show: bool, comptime fmt: []const u8, args: anytype) void {
    if (!show) {
        return;
    }

    std.debug.print(fmt, args);
}
