const std = @import("std");
const file = @import("../lib/file.zig");
const String = @import("../lib/string.zig").String;

pub fn getInput(allocator: std.mem.Allocator, day: u8) !String {
    const path = try std.fmt.allocPrint(allocator, "src/day{d}.input", .{day});
    defer allocator.free(path);

    return file.readAllText(allocator, path) catch {
        const sessionValue = std.process.getEnvVarOwned(allocator, "SESSION") catch |err| switch (err) {
            error.EnvironmentVariableNotFound => blk: {
                var fileSession = try file.readAllText(allocator, ".session");
                defer fileSession.deinit();
                break :blk try allocator.dupe(u8, std.mem.trim(u8, fileSession.contents, " \t\r\n"));
            },
            else => return err,
        };
        defer allocator.free(sessionValue);

        const trimmedSession = std.mem.trim(u8, sessionValue, " \t\r\n");
        const cookieHeader = try std.fmt.allocPrint(allocator, "session={s}", .{trimmedSession});
        defer allocator.free(cookieHeader);

        const url = try std.fmt.allocPrint(allocator, "https://adventofcode.com/2025/day/{d}/input", .{day});
        defer allocator.free(url);

        var httpClient = std.http.Client{ .allocator = allocator };
        defer httpClient.deinit();

        var body = std.Io.Writer.Allocating.init(allocator);
        defer body.deinit();

        const uri = try std.Uri.parse(url);
        const headers = [_]std.http.Header{.{ .name = "Cookie", .value = cookieHeader }};

        const response = try httpClient.fetch(.{
            .method = .GET,
            .location = .{ .uri = uri },
            .response_writer = &body.writer,
            .extra_headers = &headers,
        });

        if (response.status != .ok) {
            @panic("Handle errors");
        }

        const handle = try std.fs.cwd().createFile(path, .{});
        try handle.writeAll(body.written());
        handle.close();

        return file.readAllText(allocator, path);
    };
}
