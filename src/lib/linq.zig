const std = @import("std");
const List = @import("list.zig").List;
const String = @import("string.zig").String;

pub fn WhereIterator(comptime T: type, comptime IteratorType: type, comptime TContext: type) type {
    return struct {
        context: TContext,
        iterator: IteratorType,
        predicate: ?*const fn (TContext, T) bool,

        const Self = @This();

        pub fn next(self: *Self) ?T {
            while (self.iterator.next()) |item| {
                if (self.predicate == null or self.predicate.?(self.context, item)) {
                    return item;
                }
            }
            return null;
        }
    };
}

pub fn SelectIterator(comptime T: type, comptime T2: type, comptime IteratorType: type, comptime TContext: type) type {
    return struct {
        context: TContext,
        iterator: IteratorType,
        selector: *const fn (TContext, T) T2,

        const Self = @This();

        pub fn next(self: *Self) ?T2 {
            while (self.iterator.next()) |item| {
                return self.selector(self.context, item);
            }
            return null;
        }
    };
}

pub fn SplitIterator(comptime delimiter_type: std.mem.DelimiterType) type {
    return struct {
        trim_empty: bool,
        iterator: std.mem.SplitIterator(u8, delimiter_type),

        const Self = @This();

        pub fn next(self: *Self) ?[]const u8 {
            while (self.iterator.next()) |value| {
                if (self.trim_empty and String.isNullOrWhitespace(value)) {
                    continue;
                }

                return value;
            }
            return null;
        }
    };
}

pub fn Lookup(comptime TKey: type, comptime TValue: type) type {
    return struct {
        allocator: std.mem.Allocator,
        hashmap: std.AutoHashMap(TKey, *List(TValue)),

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, hashmap: std.AutoHashMap(TKey, *List(TValue))) Self {
            return .{ .allocator = allocator, .hashmap = hashmap };
        }

        pub fn get(self: *const Self, key: TKey) ?*List(TValue) {
            return self.hashmap.get(key);
        }

        pub fn has(self: *const Self, key: TKey) bool {
            return self.hashmap.contains(key);
        }

        pub fn deinit(self: *Self) void {
            var iter = self.hashmap.valueIterator();
            while (iter.next()) |i| {
                const listPtr = i.*;
                listPtr.deinit();
                self.allocator.destroy(listPtr);
            }

            self.hashmap.deinit();
        }
    };
}

pub fn where(comptime T: type, iterable: anytype, context: anytype, comptime predicate: fn (@TypeOf(context), T) bool) WhereIterator(T, @TypeOf(iterable), @TypeOf(context)) {
    ensureIterable(iterable);
    return WhereIterator(@TypeOf(context), T, @TypeOf(iterable)){ .context = context, .iterator = iterable, .predicate = predicate };
}

pub fn select(comptime TSource: type, comptime TTarget: type, iterable: anytype, context: anytype, comptime selector: fn (@TypeOf(context), TSource) TTarget) SelectIterator(TSource, TTarget, @TypeOf(iterable), @TypeOf(context)) {
    ensureIterable(iterable);
    return SelectIterator(@TypeOf(context), TSource, TTarget, @TypeOf(iterable)){ .context = context, .iterator = iterable, .selector = selector };
}

pub fn toLookup(comptime TKey: type, comptime TValue: type, iter: anytype, context: anytype, comptime keySelector: fn (@TypeOf(context), TValue) TKey, allocator: std.mem.Allocator) !Lookup(TKey, TValue) {
    return toLookupWithContext(TKey, TValue, null, iter, struct {
        pub fn wrapper(_: anytype, value: TValue) TKey {
            return keySelector(context, value);
        }
    }.wrapper, allocator);
}

pub fn toLookupWithContext(comptime TKey: type, comptime TValue: type, context: anytype, iter: anytype, comptime keySelector: fn (@TypeOf(context), TValue) TKey, allocator: std.mem.Allocator) !Lookup(TKey, TValue) {
    ensureIterable(iter);

    var map = std.AutoHashMap(TKey, *List(TValue)).init(allocator);
    var iterator = iter;
    while (iterator.next()) |item| {
        const key = keySelector(context, item);
        if (!map.contains(key)) {
            const list = try allocator.create(List(TValue));
            list.* = try List(TValue).init(allocator);
            try map.put(key, list);
        }

        const values = map.get(key);
        if (values) |v| {
            try v.add(item);
        } else {
            unreachable;
        }
    }

    return Lookup(TKey, TValue).init(allocator, map);
}

pub fn toList(comptime T: type, iter: anytype, allocator: std.mem.Allocator) !List(T) {
    ensureIterable(iter);

    var iterable = iter; // Make a mutable copy
    var list = try List(T).init(allocator);
    while (iterable.next()) |item| {
        try list.add(item);
    }
    return list;
}

pub fn split(string: anytype, delimiter: [:0]const u8, trim_empty: bool) !SplitIterator(.sequence) {
    const isString = comptime (@TypeOf(string) == String);
    const isStringPtr = comptime (@TypeOf(string) == *const String or @TypeOf(string) == *String);
    const rawString = if (isString) string.get() else if (isStringPtr) string.*.get() else string;

    const it = std.mem.splitSequence(u8, rawString, delimiter);
    return SplitIterator(.sequence){ .iterator = it, .trim_empty = trim_empty };
}

pub fn deinit(input: anytype) void {
    if (!@hasDecl(@TypeOf(input), "next")) {
        if (!@hasDecl(@TypeOf(input), "iterator")) {
            @compileError("This function only works on structs exposing iterators or iterators themselves!");
        }
    }

    var iter = if (!@hasDecl(@TypeOf(input), "next")) input.iterator() else input;
    if (!@hasDecl(@TypeOf(iter), "next")) {
        @compileError("This function only works on structs exposing iterators or iterators themselves!");
    }

    while (iter.next()) |item| {
        if (@hasDecl(@TypeOf(item), "deinit")) {
            item.deinit();
        }
    }
}

fn ensureIterable(iter: anytype) void {
    if (!@hasDecl(@TypeOf(iter), "next")) {
        @compileError("Iterable must have a 'next' method");
    }
}

fn InferReturnType(comptime Selector: type) type {
    return @typeInfo(Selector).@"fn".return_type.?;
}

fn InferItemType(comptime IteratorType: type) type {
    const PtrType = IteratorType;
    const return_type = @typeInfo(@TypeOf(PtrType.next)).@"fn".return_type.?;

    // Unwrap the optional ?T to get T
    return @typeInfo(return_type).optional.child;
}
