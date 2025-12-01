const std = @import("std");

pub fn deinitIfPossible(item: anytype, allocator: std.mem.Allocator) void {
    const T = @TypeOf(item);
    const type_info = @typeInfo(T);

    // Handle pointer types - dereference to get the actual type
    if (type_info == .pointer) {
        const child_type = type_info.pointer.child;
        if (@hasDecl(child_type, "deinit")) {
            item.deinit();
            return;
        }
    }

    // Handle non-pointer types
    if (@hasDecl(T, "deinit")) {
        const deinit_fn = @TypeOf(T.deinit);
        const deinit_info = @typeInfo(deinit_fn);

        switch (deinit_info) {
            .@"fn" => |func| {
                if (func.params.len == 2) {
                    item.deinit(allocator);
                } else if (func.params.len == 1) {
                    item.deinit();
                }
            },
            else => {},
        }
    }
}
