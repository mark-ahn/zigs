const std = @import("std");
const testing = std.testing;

const gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn init() !void {}
pub fn deinit() void {
    defer if (gpa.deinit() == .leak) std.debug.panic("memory leak @ zigs.deinit()", .{});
}
