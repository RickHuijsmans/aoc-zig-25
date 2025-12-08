const std = @import("std");
const String = @import("lib/string.zig").String;
const linq = @import("lib/linq.zig");
const file = @import("lib/file.zig");
const dayHelper = @import("utility/day-helper.zig");
const inputHelper = @import("utility/input-helper.zig");
const utility = @import("lib/utility.zig");
const List = @import("lib/list.zig").List;

const Vec3 = struct {
    x: i64,
    y: i64,
    z: i64,

    pub fn distance(self: *const Vec3, other: Vec3) f32 {
        return std.math.sqrt(@as(f32, @floatFromInt(self.distanceSq(other))));
    }

    pub fn distanceSq(self: *const Vec3, other: Vec3) i64 {
        return std.math.pow(i64, other.x - self.x, 2) + std.math.pow(i64, other.y - self.y, 2) + std.math.pow(i64, other.z - self.z, 2);
    }
};

const Edge = struct {
    left: usize,
    right: usize,
    distance: i64,

    pub fn lessThan(_: void, left: Edge, right: Edge) bool {
        return left.distance < right.distance;
    }
};

const DisjointSet = struct {
    parents: []usize,
    circuitSizes: []usize,
    circuits: usize,

    pub fn init(alloc: std.mem.Allocator, size: usize) !DisjointSet {
        const parents = try alloc.alloc(usize, size);
        const circuits = try alloc.alloc(usize, size);

        for (0..size) |i| {
            parents[i] = i;
            circuits[i] = 1;
        }

        return DisjointSet{ .parents = parents, .circuitSizes = circuits, .circuits = size };
    }

    pub fn findCircuit(self: *DisjointSet, index: usize) usize {
        if (self.parents[index] == index) {
            return index;
        }

        self.parents[index] = self.findCircuit(self.parents[index]);
        return self.parents[index];
    }

    pub fn unionSets(self: *DisjointSet, left: usize, right: usize) bool {
        const rootLeft = self.findCircuit(left);
        const rootRight = self.findCircuit(right);

        if (rootLeft == rootRight) {
            return false;
        }

        const circuitSizeLeft = self.circuitSizes[rootLeft];
        const circuitSizeRight = self.circuitSizes[rootRight];

        if (circuitSizeLeft < circuitSizeRight) {
            self.parents[rootLeft] = rootRight;
            self.circuitSizes[rootRight] += circuitSizeLeft;
        } else {
            self.parents[rootRight] = rootLeft;
            self.circuitSizes[rootLeft] += circuitSizeRight;
        }

        self.circuits -= 1;
        return true;
    }

    fn updateCircuitCount(self: *DisjointSet) void {
        var count: usize = 0;
        for (0..self.parents.len) |i| {
            if (self.parents[i] == i) {
                count += 1;
            }
        }

        self.circuits = count;
    }
};

pub const Day8 = struct {
    day: u8,
    debugMode: bool,
    allocator: std.mem.Allocator,

    pub fn debug(self: *const Day8, comptime fmt: []const u8, args: anytype) void {
        dayHelper.printDebug(self.debugMode, fmt, args);
    }

    pub fn debugLine(self: *const Day8, comptime fmt: []const u8, args: anytype) void {
        self.debug("\n" ++ fmt, args);
    }

    pub fn init(allocator: std.mem.Allocator, debugMode: bool) Day8 {
        return .{ .day = 8, .allocator = allocator, .debugMode = debugMode };
    }

    const sample1 = String.initFixed(
        \\162,817,812
        \\57,618,57
        \\906,360,560
        \\592,479,940
        \\352,342,300
        \\466,668,158
        \\542,29,236
        \\431,825,988
        \\739,650,466
        \\52,470,668
        \\216,146,977
        \\819,987,18
        \\117,168,530
        \\805,96,715
        \\346,949,466
        \\970,615,88
        \\941,993,340
        \\862,61,35
        \\984,92,344
        \\425,690,689
    );

    pub fn solveSample1(self: *const Day8) !u64 {
        return self.solve1(self.allocator, &sample1);
    }

    pub fn solve1(self: *const Day8, alloc: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        var points = try List(Vec3).init(alloc);
        var edges = try List(Edge).init(alloc);

        while (rows.next()) |row| {
            var vec = Vec3{ .x = 0, .y = 0, .z = 0 };
            var start: ?usize = null;
            for (0..row.len + 1) |i| {
                if (i >= row.len or row[i] == ',') {
                    const slice = row[start.?..i];
                    const num = try String.parseInt(slice, u32);
                    if (vec.x == 0) {
                        vec.x = num;
                    } else if (vec.y == 0) {
                        vec.y = num;
                    } else {
                        vec.z = num;
                    }
                    start = null;
                } else if (start == null) {
                    start = i;
                }
            }

            try points.add(vec);
        }

        for (0..points.count()) |i| {
            for (i + 1..points.count()) |j| {
                const distance = points.get(i).distanceSq(points.get(j));
                try edges.add(Edge{ .left = i, .right = j, .distance = distance });
            }
        }

        edges.sort(Edge.lessThan);

        const targetPairs: usize = if (points.count() == 20) 10 else 1000;
        var disjointSet = try DisjointSet.init(alloc, points.count());
        var connections: u32 = 0;

        for (0..targetPairs) |i| {
            const edge = edges.get(i);

            if (disjointSet.unionSets(edge.left, edge.right)) {
                connections += 1;
            }

            const left = points.get(edge.left);
            const right = points.get(edge.right);
            self.debugLine("({}, {}, {}) <> ({}, {}, {}) = {}", .{ left.x, left.y, left.z, right.x, right.y, right.z, edge.distance });
        }

        var sizes = try List(usize).init(alloc);
        for (0..disjointSet.parents.len) |i| {
            if (disjointSet.parents[i] == i) {
                try sizes.add(disjointSet.circuitSizes[i]);
            }
        }

        sizes.sort(std.sort.desc(usize));
        return sizes.get(0) * sizes.get(1) * sizes.get(2);
    }

    pub fn solveSample2(self: *const Day8) !u64 {
        return self.solve2(self.allocator, &sample1);
    }

    pub fn solve2(self: *const Day8, alloc: std.mem.Allocator, input: *const String) !u64 {
        var rows = try linq.split(input, "\n", true);
        var points = try List(Vec3).init(alloc);
        var edges = try List(Edge).init(alloc);

        while (rows.next()) |row| {
            var vec = Vec3{ .x = 0, .y = 0, .z = 0 };
            var start: ?usize = null;
            for (0..row.len + 1) |i| {
                if (i >= row.len or row[i] == ',') {
                    const slice = row[start.?..i];
                    const num = try String.parseInt(slice, u32);
                    if (vec.x == 0) {
                        vec.x = num;
                    } else if (vec.y == 0) {
                        vec.y = num;
                    } else {
                        vec.z = num;
                    }
                    start = null;
                } else if (start == null) {
                    start = i;
                }
            }

            try points.add(vec);
        }

        for (0..points.count()) |i| {
            for (i + 1..points.count()) |j| {
                const distance = points.get(i).distanceSq(points.get(j));
                try edges.add(Edge{ .left = i, .right = j, .distance = distance });
            }
        }

        edges.sort(Edge.lessThan);

        var disjointSet = try DisjointSet.init(alloc, points.count());
        var lastEdge: ?Edge = null;

        var i: usize = 0;
        while (disjointSet.circuits > 1) : (i += 1) {
            const edge = edges.get(i);

            if (disjointSet.unionSets(edge.left, edge.right)) {
                lastEdge = edge;
            }
        }

        if (lastEdge == null) {
            @panic("No final edge?????");
        }

        const left = points.get(lastEdge.?.left);
        const right = points.get(lastEdge.?.right);
        self.debugLine("({}, {}, {}) <> ({}, {}, {})", .{ left.x, left.y, left.z, right.x, right.y, right.z });
        const leftX: usize = @intCast(left.x);
        const rightX: usize = @intCast(right.x);

        return leftX * rightX;
    }
};

test "Sample 1" {
    const context = dayHelper.initTest(Day8);
    const result = try context.day.solveSample1();
    try std.testing.expectEqual(40, result);
}

test "Solve 1" {
    const context = dayHelper.initTest(Day8);
    const input = try context.getInput();
    const result = try context.day.solve1(context.allocator, &input);
    try std.testing.expectEqual(80446, result);
}

test "Sample 2" {
    const context = dayHelper.initTest(Day8);
    const result = try context.day.solveSample2();
    try std.testing.expectEqual(25272, result);
}

test "Solve 2" {
    const context = dayHelper.initTest(Day8);
    const input = try context.getInput();
    const result = try context.day.solve2(context.allocator, &input);
    try std.testing.expectEqual(51294528, result);
}
