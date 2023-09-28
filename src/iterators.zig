const std = @import("std");
const testing = std.testing;

pub fn Iterator(comptime Context: type, comptime Item: type, comptime methods: struct {
    next: fn (Context) ?Item,
}) type {
    _ = methods;
    return struct {
        pub const IFace = struct {
            impl: Context,
            const Self = @This();
            fn next(self: Self) ?Item {
                return next(self.impl);
            }
        };

        pub const @"zigs.Iterator" = IFace;
        pub fn iterator(self: Context) IFace {
            return .{ .impl = self };
        }
    };
}

fn nonComptimeInt(comptime T: type) type {
    return comptime switch (@typeInfo(T)) {
        .Int => T,
        .ComptimeInt => u128,
        else => @compileError(std.fmt.comptimePrint("expects interger, got {any}", .{T})),
    };
}

test Iterator {
    const local = struct {
        fn numbers(len: anytype) Numbers(nonComptimeInt(@TypeOf(len))) {
            const l = comptime switch (@typeInfo(@TypeOf(len))) {
                .Int => len,
                .ComptimeInt => @as(u128, len),
                else => @compileError(std.fmt.comptimePrint("expects interger, got {any}", .{@TypeOf(len)})),
            };
            return Numbers(@TypeOf(l)){
                .index = 0,
                .end = l,
            };
        }
        fn Numbers(comptime Item: type) type {
            return struct {
                index: Item,
                end: Item,
                pub usingnamespace Iterator(*Context, Item, .{
                    .next = next,
                });
                const Context = @This();
                // const Item = @TypeOf(len);

                fn next(self: *Context) ?Item {
                    if (self.end <= self.index) return null;
                    defer self.index +|= 1;
                    return self.index;
                }
            };
        }
    };

    var rng = local.numbers(10);
    while (rng.next()) |n| {
        std.debug.print("{d}\n", .{n});
    }
}
