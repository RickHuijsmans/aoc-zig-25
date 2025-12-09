const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");
const Stopwatch = @import("lib/stopwatch.zig").Stopwatch;
const List = @import("lib/list.zig").List;

const Vec2 = @Vector(2, i64);

const Rectangle = struct {
    p1: Vec2,
    p2: Vec2,
    area: u64,
    pub fn corners(self: *const Rectangle) [4]Vec2 {
        return [4]Vec2{ Vec2{ @min(self.p1[0], self.p2[0]), @min(self.p1[1], self.p2[1]) }, Vec2{ @max(self.p1[0], self.p2[0]), @min(self.p1[1], self.p2[1]) }, Vec2{ @max(self.p1[0], self.p2[0]), @max(self.p1[1], self.p2[1]) }, Vec2{ @min(self.p1[0], self.p2[0]), @max(self.p1[1], self.p2[1]) } };
    }
};

pub const Day9 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day9, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day9, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day9 {
        return .{ .day = 9, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\7,1
        \\11,1
        \\11,7
        \\9,7
        \\9,5
        \\2,5
        \\2,3
        \\7,3
    );

    pub fn solveSample1(self: *const Day9) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(_: *const Day9, alloc: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        var positions = try List(Vec2).init(alloc);
        while (rows.next()) |row| {
            var vec = Vec2{ 0, 0 };
            var start: ?usize = null;
            for (0..row.len + 1) |i| {
                if (i >= row.len or row[i] == ',') {
                    const slice = row[start.?..i];
                    const num = try String.parseInt(slice, i32);

                    if (start.? > 0) {
                        vec[1] = num;
                    } else {
                        vec[0] = num;
                    }

                    start = null;
                } else if (start == null) {
                    start = i;
                }
            }

            try positions.add(vec);
        }

        var maxArea: i64 = 0;
        for (0..positions.count()) |i| {
            for (i + 1..positions.count()) |j| {
                const left = positions.get(i);
                const right = positions.get(j);
                const width = (if (left[0] > right[0]) left[0] - right[0] else right[0] - left[0]) + 1;
                const height = (if (left[1] > right[1]) left[1] - right[1] else right[1] - left[1]) + 1;
                const area = width * height;

                if (area > maxArea) {
                    maxArea = area;
                }
            }
        }

        return @intCast(maxArea);
    }

    pub fn solveSample2(self: *const Day9) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    fn lineIntersects(p0: Vec2, p1: Vec2, p2: Vec2, p3: Vec2) bool {
        const p0x: f32 = @floatFromInt(p0[0]);
        const p0y: f32 = @floatFromInt(p0[1]);
        const p1x: f32 = @floatFromInt(p1[0]);
        const p1y: f32 = @floatFromInt(p1[1]);
        const p2x: f32 = @floatFromInt(p2[0]);
        const p2y: f32 = @floatFromInt(p2[1]);
        const p3x: f32 = @floatFromInt(p3[0]);
        const p3y: f32 = @floatFromInt(p3[1]);

        const s1x = p1x - p0x;
        const s1y = p1y - p0y;
        const s2x = p3x - p2x;
        const s2y = p3y - p2y;

        const denom = -s2x * s1y + s1x * s2y;
        const epsilon = 1e-5;

        if (@abs(denom) < epsilon) {
            return false;
        }

        const s = (-s1y * (p0x - p2x) + s1x * (p0y - p2y)) / denom;
        const t = (s2x * (p0y - p2y) - s2y * (p0x - p2x)) / denom;
        return (s > epsilon and s < (1.0 - epsilon) and t > epsilon and t < (1.0 - epsilon));
    }

    fn isPointInsideOrOnEdge(px: i64, py: i64, edges: *List([2]Vec2)) bool {
        const pxf: f32 = @floatFromInt(px);
        const pyf: f32 = @floatFromInt(py);
        var inside = false;

        for (0..edges.count()) |i| {
            const edge = edges.get(i);
            const p1x = edge[0][0];
            const p1y = edge[0][1];
            const p2x = edge[1][0];
            const p2y = edge[1][1];

            // Edge check
            if ((p1x == p2x and px == p1x and py >= @min(p1y, p2y) and py <= @max(p1y, p2y)) or (p1y == p2y and py == p1y and px >= @min(p1x, p2x) and px <= @max(p1x, p2x))) {
                return true;
            }

            const p1xf: f32 = @floatFromInt(p1x);
            const p1yf: f32 = @floatFromInt(p1y);
            const p2xf: f32 = @floatFromInt(p2x);
            const p2yf: f32 = @floatFromInt(p2y);

            // Ray cast magic
            if (((p1yf > pyf) != (p2yf > pyf)) and
                (pxf < (p2xf - p1xf) * (pyf - p1yf) / (p2yf - p1yf) + p1xf))
            {
                inside = !inside;
            }
        }
        return inside;
    }

    pub fn solve2(self: *const Day9, alloc: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        var positions = try List(Vec2).init(alloc);
        var edges = try List([2]Vec2).init(alloc);
        var lastVec: ?Vec2 = null;

        while (rows.next()) |row| {
            var vec = Vec2{ 0, 0 };
            var start: ?usize = null;
            for (0..row.len + 1) |i| {
                if (i >= row.len or row[i] == ',') {
                    const slice = row[start.?..i];
                    const num = try String.parseInt(slice, i32);

                    if (start.? > 0) {
                        vec[1] = num;
                    } else {
                        vec[0] = num;
                    }

                    start = null;
                } else if (start == null) {
                    start = i;
                }
            }

            try positions.add(vec);
            if (lastVec) |v| {
                try edges.add([2]Vec2{ v, vec });
            }

            lastVec = vec;
        }

        if (lastVec) |v| {
            try edges.add([2]Vec2{ v, edges.get(0)[0] });
        }

        const biggerThan = struct {
            fn biggerThan(_: void, left: Rectangle, right: Rectangle) bool {
                return left.area > right.area;
            }
        }.biggerThan;

        var rectangles = try List(Rectangle).init(alloc);
        for (0..positions.count()) |i| {
            for (i + 1..positions.count()) |j| {
                const p1 = positions.get(i);
                const p2 = positions.get(j);

                const min_x = @min(p1[0], p2[0]);
                const max_x = @max(p1[0], p2[0]);
                const min_y = @min(p1[1], p2[1]);
                const max_y = @max(p1[1], p2[1]);
                const w = @as(u64, @intCast(max_x - min_x + 1));
                const h = @as(u64, @intCast(max_y - min_y + 1));

                try rectangles.add(Rectangle{
                    .p1 = Vec2{ min_x, min_y },
                    .p2 = Vec2{ max_x, max_y },
                    .area = w * h,
                });
            }
        }

        rectangles.sort(biggerThan);

        self.debugLine("Edges: {}", .{edges.count()});
        outer: for (0..rectangles.count()) |i| {
            const rectangle = rectangles.get(i);
            const rectEdges = rectangle.corners();
            inline for (0..rectEdges.len) |k| {
                const point = rectEdges[k];
                if (!isPointInsideOrOnEdge(point[0], point[1], &edges)) {
                    continue :outer;
                }

                const prevPos = if (k == 0) rectEdges[3] else rectEdges[k - 1];
                const pos = rectEdges[k];

                for (0..edges.count()) |j| {
                    const polygonLine = edges.get(j);
                    if (lineIntersects(prevPos, pos, polygonLine[0], polygonLine[1])) {
                        continue :outer;
                    }
                }
            }

            return rectangle.area;
        }

        return 0;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day9);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(50, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day9);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(4748985168, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day9);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(24, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day9);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(1550760868, result);
}
