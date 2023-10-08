const std = @import("std");
const testing = std.testing;

// pub fn Iterable(comptime Item: type) type {

// }

pub fn Iterator(comptime Context: type, comptime Item: type, comptime methods: struct {
    next: fn (Context) ?Item,
}) type {
    return struct {
        pub const IFace = struct {
            impl: Context,
            const Self = @This();
            pub fn next(self: Self) ?Item {
                return methods.next(self.impl);
            }
        };
        // pub const IFace = IteratorIFace(Context, Item, methods);

        pub const @"zigs.Iterator" = IFace;
        pub fn iterator(self: Context) IFace {
            return .{ .impl = self };
        }
    };
}

pub fn IteratorIFace(comptime Context: type, comptime Item: type, comptime methods: struct {
    next: fn (Context) ?Item,
}) type {
    const IFace = struct {
        // impl: Context,
        // const Self = @This();
        pub fn next(self: Context) ?Item {
            // std.debug.print("iface\n", .{});
            return methods.next(self);
        }
    };

    return IFace;
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

        fn SomeContainer(comptime Item: type) type {
            return struct {
                items: []Item,
                pub fn iter(self: *@This()) SomeContainerIter(Item) {
                    return .{
                        .container = self,
                    };
                }
            };
        }

        fn SomeContainerIter(comptime Item: type) type {
            return struct {
                container: *SomeContainer(Item),
                index: usize = 0,
                pub usingnamespace IteratorIFace(*Context, Item, .{
                    .next = next_,
                });
                const Context = @This();
                fn next_(self: *Context) ?Item {
                    // std.debug.print("next_ {*} {d}\n", .{ self.container, self.index });
                    if (self.container.items.len <= self.index) return null;
                    defer self.index +|= 1;
                    return self.container.items[self.index];
                }
            };
        }
    };

    var rng = local.numbers(10);
    // while (rng.next()) |n| {
    while (rng.iterator().next()) |n| {
        std.debug.print("{d}\n", .{n});
    }

    var array = [_]u32{ 1, 2, 3 };
    var some = local.SomeContainer(u32){ .items = &array };
    var iter = some.iter();
    // std.debug.print("iter.init: {*} {d}\n", .{ iter.container, iter.index });

    var i: usize = 0;
    while (iter.next()) |d| : (i += 1) {
        // if (3 < i) break;
        // _ = d;
        std.debug.print("iter: {d}\n", .{d});
    }
}
