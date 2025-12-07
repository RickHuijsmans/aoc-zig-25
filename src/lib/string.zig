const std = @import("std");
const list = @import("list.zig");

pub const String = struct {
    allocator: ?std.mem.Allocator = null,
    contents: []const u8,
    size: usize,

    pub fn init(allocator: std.mem.Allocator, bytes: []const u8) !String {
        const is_terminated = isNullTerminated(bytes);
        const buffer = try allocator.alloc(u8, if (is_terminated) bytes.len else bytes.len + 1);
        @memcpy(buffer[0..bytes.len], bytes);
        buffer[buffer.len - 1] = 0;

        return .{ .allocator = allocator, .contents = buffer, .size = buffer.len };
    }

    pub fn initFixed(comptime bytes: []const u8) String {
        const terminated = bytes ++ &[_]u8{0};
        return .{ .contents = terminated, .size = terminated.len };
    }

    pub fn clone(self: *const String, allocator: std.mem.Allocator) !String {
        return init(allocator, self.contents);
    }

    pub fn cloneWriteable(self: *const String, allocator: std.mem.Allocator) ![]u8 {
        const copy = try allocator.alloc(u8, self.size);
        std.mem.copyForwards(u8, copy, self.contents);
        return copy;
    }

    pub fn deinit(self: *String) void {
        if (self.allocator) |alloc| {
            alloc.free(self.contents);
        }
    }

    pub fn get(self: *const String) []const u8 {
        if (self.size <= 0)
            return self.contents[0..0];

        return self.contents[0 .. self.size - 1];
    }

    pub fn getTerminated(self: *const String) [:0]const u8 {
        if (self.size <= 0)
            return self.contents[0..0 :0];

        return self.contents[0 .. self.size - 1 :0];
    }

    pub fn split(self: *const String, delimiter: [:0]const u8, trim_empty: bool, allocator: std.mem.Allocator) !list.List(String) {
        var results = try list.List(String).init(allocator);
        var it = std.mem.splitAny(u8, self.contents, delimiter);

        while (it.next()) |result| {
            if (trim_empty and isNullOrWhitespace(result))
                continue;

            try results.add(try String.init(allocator, result));
        }

        return results;
    }

    pub fn splitMut(self: *const String, delimiter: [:0]const u8, trim_empty: bool, allocator: std.mem.Allocator) !list.List([]u8) {
        var results = try list.List([]u8).init(allocator);
        var it = std.mem.splitAny(u8, self.contents, delimiter);

        while (it.next()) |result| {
            if (trim_empty and isNullOrWhitespace(result))
                continue;

            const copy = try allocator.dupe(u8, result);
            try results.add(copy);
        }

        return results;
    }

    pub fn startsWith(self: *const String, searchString: []const u8) bool {
        return std.mem.startsWith(u8, self.contents, searchString);
    }

    pub fn indexOf(string: anytype, char: u8) ?usize {
        const raw = getRawString(string);
        for (0..raw.len) |index| {
            if (raw[index] == char) {
                return index;
            }
        }

        return null;
    }

    pub fn parseInt(string: anytype, comptime T: type) !T {
        const rawString = getRawString(string);
        return std.fmt.parseInt(T, rawString, 10) catch |e| {
            std.debug.print("Error whilst trying to parse '{s}' as an integer!", .{rawString});
            return e;
        };
    }

    pub fn getRawString(string: anytype) []const u8 {
        if (@TypeOf(string) == String or @TypeOf(string) == *String or @TypeOf(string) == *const String) {
            return string.get();
        } else {
            return string;
        }
    }

    pub fn trimWhitespace(self: *const String, allocator: std.mem.Allocator) !String {
        var startFound = false;
        var startPos: usize = 0;
        var endPos: usize = 0;

        for (0..self.size) |i| {
            if (String.isWhitespace(self.contents[i])) {
                continue;
            }

            if (!startFound) {
                startPos = i;
                startFound = true;
            }

            endPos = i + 1;
        }

        const slice = self.contents[startPos..endPos];
        return String.init(allocator, slice);
    }

    pub fn stringReplace(self: *const String, allocator: std.mem.Allocator, needle: anytype, replacement: anytype) !String {
        return replace(allocator, getRawString(self), needle, replacement);
    }

    pub fn replace(allocator: std.mem.Allocator, string: anytype, needle: anytype, replacement: anytype) !String {
        const str = getRawString(string);
        const needleStr = getRawString(needle);
        const replacementStr = getRawString(replacement);

        const size = std.mem.replacementSize(u8, str, needleStr, replacementStr);
        const output = try allocator.alloc(u8, size);
        defer allocator.free(output);

        _ = std.mem.replace(u8, str, needleStr, replacementStr, output);
        return String.init(allocator, output);
    }

    pub fn replaceInPlace(self: *String, needle: anytype, replacement: anytype) void {
        const needleStr = getRawString(needle);
        const replacementStr = getRawString(replacement);
        std.mem.replaceScalar(u8, self.contents, needleStr, replacementStr);
    }

    pub fn isNullOrWhitespace(string: []const u8) bool {
        if (string.len <= 0)
            return true;

        for (string) |char| {
            if (!isWhitespace(char))
                return false;
        }

        return true;
    }

    pub fn isWhitespace(char: u8) bool {
        return switch (char) {
            0, ' ', '\t', '\n', '\r' => true,
            else => false,
        };
    }

    pub fn isDigit(char: u8) bool {
        return char >= '0' and char <= '9';
    }

    pub fn isNullTerminated(string: []const u8) bool {
        return string.len > 0 and string[string.len - 1] == 0;
    }
};
