const std = @import("std");
const utility = @import("utility.zig");

pub fn ListIterator(comptime T: type) type {
    return struct {
        list: *List(T),
        index: usize,

        pub fn next(self: *@This()) ?T {
            if (self.index >= self.list.count()) {
                return null;
            }

            const result = self.list.get(self.index);
            self.index += 1;
            return result;
        }
    };
}

pub fn List(comptime T: type) type {
    return struct {
        items: std.ArrayList(T),
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !Self {
            return initCapacity(allocator, 0);
        }

        pub fn initCapacity(allocator: std.mem.Allocator, num: usize) !Self {
            return .{ .items = try std.ArrayList(T).initCapacity(allocator, num), .allocator = allocator };
        }

        pub fn from(allocator: std.mem.Allocator, it: *ListIterator(T)) !Self {
            var instance = try Self.init(allocator);
            var i: usize = 0;
            while (it.next()) |value| {
                instance.add(value);
                i += 1;
            }

            return instance;
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit(self.allocator);
        }

        pub fn deinitAll(self: *Self) void {
            for (self.items.items) |*item| {
                utility.deinitIfPossible(item, self.allocator);
            }

            self.items.deinit(self.allocator);
        }

        pub fn iterator(self: *Self) ListIterator(T) {
            return .{ .list = self, .index = 0 };
        }

        pub fn asSlice(self: *Self) []T {
            return self.items.items;
        }

        pub fn constSlice(self: *const Self) []const T {
            return self.items.items;
        }

        pub fn get(self: *const Self, index: usize) T {
            return self.items.items[index];
        }

        pub fn set(self: *Self, index: usize, item: T) void {
            self.items.items[index] = item;
        }

        pub fn getSafe(self: *const Self, index: usize) ?T {
            const len = self.count();
            if (index >= len) {
                return null;
            }

            return self.get(index);
        }

        pub fn first(self: *const Self) T {
            return self.items.items[0];
        }

        pub fn firstOrDefault(self: *const Self) ?T {
            return if (self.count() <= 0) null else self.first();
        }

        pub fn last(self: *const Self) T {
            return self.items.items[self.items.items.len - 1];
        }

        pub fn lastOrDefault(self: *const Self) ?T {
            return if (self.count() <= 0) null else self.last();
        }

        pub fn filter(self: *const Self, context: anytype, comptime predicate: fn (@TypeOf(context), T) bool, allocator: std.mem.Allocator) !Self {
            var result = try Self.init(allocator);
            for (self.items.items) |item| {
                if (predicate(context, item)) {
                    try result.add(item);
                }
            }
            return result;
        }

        pub fn sort(self: *Self, comptime sortFn: fn (void, lhs: T, rhs: T) bool) void {
            std.mem.sort(T, self.items.items, {}, sortFn);
        }

        pub fn map(self: *const Self, comptime T2: type, context: anytype, comptime selector: fn (@TypeOf(context), T) anyerror!T2, allocator: std.mem.Allocator) !List(T2) {
            var result = try List(T2).init(allocator);
            for (self.items.items) |item| {
                try result.add(try selector(context, item));
            }
            return result;
        }

        pub fn add(self: *Self, item: T) error{OutOfMemory}!void {
            try self.items.append(self.allocator, item);
        }

        pub fn clear(self: *Self) void {
            self.items.clearRetainingCapacity();
        }

        pub fn remove(self: *Self, item: T) bool {
            const index = self.indexOf(item);
            return self.removeByIndex(@intCast(index));
        }

        pub fn removeByIndex(self: *Self, index: usize) bool {
            if (index < 0) {
                return false;
            }

            _ = self.items.swapRemove(index);
            return true;
        }

        pub fn pop(self: *Self) T {
            const lastIndex = self.count() - 1;
            const item = self.items.items[lastIndex];

            if (!self.removeByIndex(@intCast(lastIndex))) {
                @panic("Can't pop an empty list!");
            }

            return item;
        }

        pub fn removeAndFree(self: *Self, item: T, allocator: ?std.mem.Allocator) bool {
            if (self.remove(item)) {
                utility.deinitIfPossible(item, allocator orelse self.allocator);
                return true;
            }
            return false;
        }

        pub fn count(self: *const Self) usize {
            return self.items.items.len;
        }

        pub fn binarySearch(self: *const Self, context: anytype, comptime search: fn (context: @TypeOf(context), item: T) isize) ?T {
            var l: usize = 0;
            var r: usize = self.count() - 1;

            while (l != r) {
                const m: usize = l + @as(usize, @intFromFloat(@ceil(@as(f64, @floatFromInt(r - l)) / 2.0)));
                const v = self.get(m);
                const a = search(context, v);
                if (a == 0) {
                    return v;
                } else if (a > 0) {
                    r = m - 1;
                } else {
                    l = m;
                }
            }

            const v = self.get(l);
            const a = search(context, v);
            if (a == 0) {
                return v;
            }

            return null;
        }

        pub fn contains(self: *const Self, item: T) bool {
            return self.has(item);
        }

        pub fn has(self: *const Self, item: T) bool {
            const index = self.indexOf(item);
            return index >= 0;
        }

        pub fn indexOf(self: *const Self, item: T) isize {
            for (self.items.items, 0..) |list_item, i| {
                if (list_item == item) {
                    return @intCast(i);
                }
            }

            return -1;
        }
    };
}
