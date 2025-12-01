const std = @import("std");
const string = @import("string.zig");

pub fn getInput(allocator: std.mem.Allocator, path: []const u8) !string.String {
    const handle = if (std.fs.path.isAbsolute(path))
        try std.fs.openFileAbsolute(path, .{})
    else
        try std.fs.cwd().openFile(path, .{});

    defer handle.close();

    const file_size = try handle.getEndPos();
    const buffer = try allocator.alloc(u8, file_size + 1);
    defer allocator.free(buffer);

    _ = try handle.readAll(buffer);
    buffer[file_size] = 0;

    return string.String.init(allocator, buffer);
}
