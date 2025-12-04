const std = @import("std");
const builtin = @import("builtin");
const inputHelper = @import("utility/input-helper.zig");

pub fn runDay(comptime n: u8, allocator: std.mem.Allocator) !void {
    var arena1 = std.heap.ArenaAllocator.init(allocator);
    var arena2 = std.heap.ArenaAllocator.init(allocator);
    defer arena1.deinit();
    defer arena2.deinit();

    // Update this to add new days
    var d = switch (n) {
        1 => @import("day1.zig").Day1.init(allocator, false),
        2 => @import("day2.zig").Day2.init(allocator, false),
        3 => @import("day3.zig").Day3.init(allocator, false),
        else => return,
    };

    var input = try inputHelper.getInput(allocator, n);
    defer input.deinit();

    // Part 1
    var memBefore = arena1.queryCapacity();
    var before = std.time.microTimestamp();
    var cycles = clockCycles();

    var result = try d.solve1(arena1.allocator(), &input);

    var cyclesDiff = clockCycles() - cycles;
    var time: f64 = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    var usedMem = @as(f64, @floatFromInt(arena1.queryCapacity() - memBefore)) / 1024;

    std.debug.print("Day {d} - Part 1: {} in {} ms / {} cycles  ({d:.2} Kb)\n", .{ n, result, time, cyclesDiff, usedMem });

    // Part 2
    memBefore = arena2.queryCapacity();
    before = std.time.microTimestamp();
    cycles = clockCycles();

    result = try d.solve2(arena2.allocator(), &input);

    cyclesDiff = clockCycles() - cycles;
    time = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    usedMem = @as(f64, @floatFromInt(arena2.queryCapacity() - memBefore)) / 1024;

    std.debug.print("Day {d} - Part 2: {} in {} ms / {} cycles ({d:.2} Kb)\n", .{ n, result, time, cyclesDiff, usedMem });
}

fn clockCycles() u64 {
    switch (builtin.target.cpu.arch) {
        .x86,
        .x86_64,
        => {
            var lower: u32 = undefined;
            var higher: u32 = undefined;
            lower = asm volatile ("rdtsc"
                : [lower] "={eax}" (-> u32),
                :
                : .{ .edx = true, .eax = true });
            higher = asm volatile ("movl %%edx, %[higher]"
                : [higher] "=r" (-> u32),
                :
                : .{ .edx = true });
            return (@as(u64, higher) << 32) | (@as(u64, lower));
        },
        .riscv32,
        .riscv64,
        => if (!comptime std.Target.riscv.featureSetHas(builtin.target.cpu.features, .zicntr)) {
            return asm volatile ("rdcycle a0"
                : [a0] "={a0}" (-> usize),
                :
                : .{ .a0 = true });
        },
        .powerpc,
        .powerpcle,
        .powerpc64,
        .powerpc64le,
        => {
            const lower = asm volatile ("mfspr 0, 0x10C"
                : [lower] "={r0}" (-> u32),
                :
                : .{ .r0 = true });
            const upper = asm volatile ("mfspr 3, 0x10D"
                : [upper] "={r3}" (-> u32),
                :
                : .{ .r3 = true });
            return (@as(u64, upper) << 32) | (@as(u64, lower));
        },
        .aarch64,
        .aarch64_be,
        => {
            return asm volatile ("mrs x0, cntpct_el0"
                : [x0] "={x0}" (-> u64),
                :
                : .{ .x0 = true });
        },
        else => {},
    }
    @compileError("unsupported");
}
