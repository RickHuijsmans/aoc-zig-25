const std = @import("std");
const builtin = @import("builtin");
const inputHelper = @import("utility/input-helper.zig");
const ghActions = @import("utility/github-actions.zig");
const days = @import("days.zig");

pub fn runDay(comptime n: u8, allocator: std.mem.Allocator, summary: *ghActions.GithubActionsSummary) !void {
    // Get the day module at comptime
    const day_module = switch (n) {
        inline 1...25 => |day_num| if (@hasDecl(days, std.fmt.comptimePrint("day{d}", .{day_num})))
            @field(days, std.fmt.comptimePrint("day{d}", .{day_num}))
        else
            return,
        else => return,
    };

    const DayType = @field(day_module, std.fmt.comptimePrint("Day{d}", .{n}));

    var arena1 = std.heap.ArenaAllocator.init(allocator);
    var arena2 = std.heap.ArenaAllocator.init(allocator);
    defer arena1.deinit();
    defer arena2.deinit();

    var d = DayType.init(allocator, false);

    var input = try inputHelper.getInput(allocator, n);
    defer input.deinit();

    // Part 1
    var memBefore = arena1.queryCapacity();
    var before = std.time.microTimestamp();
    var cycles = clockCycles();

    const result1 = try d.solve1(arena1.allocator(), &input);

    var cyclesDiff = clockCycles() - cycles;
    const time1: f64 = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    var mem1: f64 = @as(f64, @floatFromInt(arena1.queryCapacity() - memBefore)) / 1024;
    summary.writeResultRow(n, 1, result1, time1, cyclesDiff, mem1);

    const unit1 = if (mem1 < 1024) "Kb" else "Mb";
    if (mem1 > 1024) {
        mem1 /= 1024;
    }

    std.debug.print("Day {d} - Part 1: {any} in {} ms / {} cycles  ({d:.2} {s})\n", .{ n, result1, time1, cyclesDiff, mem1, unit1 });

    // Part 2
    memBefore = arena2.queryCapacity();
    before = std.time.microTimestamp();
    cycles = clockCycles();

    const result2 = try d.solve2(arena2.allocator(), &input);

    cyclesDiff = clockCycles() - cycles;
    const time2: f64 = (@as(f64, @floatFromInt(std.time.microTimestamp())) - @as(f64, @floatFromInt(before))) / 1000.0;
    var mem2: f64 = @as(f64, @floatFromInt(arena2.queryCapacity() - memBefore)) / 1024;
    summary.writeResultRow(n, 2, result2, time2, cyclesDiff, mem2);

    const unit2 = if (mem2 < 1024) "Kb" else "Mb";
    if (mem2 > 1024) {
        mem2 /= 1024;
    }

    std.debug.print("Day {d} - Part 2: {any} in {} ms / {} cycles ({d:.2} {s})\n", .{ n, result2, time2, cyclesDiff, mem2, unit2 });

    // Record stats for Sankey diagrams
    summary.recordDayStats(n, time1, mem1, time2, mem2);
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
            return asm volatile ("mrs x0, cntvct_el0"
                : [x0] "={x0}" (-> u64),
                :
                : .{ .x0 = true });
        },
        else => {},
    }
    @compileError("unsupported");
}
