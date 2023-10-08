const std = @import("std");
const testing = std.testing;

pub fn Deinitializer(comptime Context: type, comptime Ok: type, comptime Error: type, comptime methods: struct {
    deinit: fn (Context) Error!Ok,
}) type {
    return struct {
        pub const IFace = struct {
            impl: Context,
            const Self = @This();
            fn deinit(self: Self) Error!Ok {
                return try methods.deinit(self.impl);
            }
        };
        pub const @"zigs.Deinitializer" = IFace;
        pub fn deinitializer(self: Context) IFace {
            return .{ .impl = self };
        }
    };
}

test Deinitializer {
    const local = struct {
        const SomeType = struct {
            ally: std.mem.Allocator,
            data: ?[]const u8,

            pub usingnamespace Deinitializer(Context, Ok, Error, .{
                .deinit = deinit,
            });
            const Context = @This();
            const Ok = void;
            const Error = error{};
            fn deinit(self: Context) Error!Ok {
                if (self.data) |the_data| {
                    self.ally.free(the_data);
                }
            }
        };
    };

    const ally = testing.allocator;
    var some = local.SomeType{
        .ally = ally,
        .data = try std.fmt.allocPrint(ally, "some {d}", .{50}),
    };
    defer some.deinitializer().deinit() catch |err| std.log.err("fail deinit: {s}", .{@errorName(err)});
    std.log.info("ok deinit", .{});
}

pub fn ArenaBox(comptime T: type) type {
    return struct {
        arena: std.heap.ArenaAllocator,
        value: *T,
        const Self = @This();
        const Error = error{};

        pub fn create(ally: std.mem.Allocator) !Self {
            var self: Self = .{
                .arena = std.heap.ArenaAllocator.init(ally),
                .value = undefined,
            };
            self.value = try self.arena.allocator().create(T);
            return self;
        }

        pub usingnamespace Deinitializer(*Self, void, Error, .{ .deinit = deinit });
        fn deinit(self: *Self) Error!void {
            self.arena.deinit();
            self.* = undefined;
        }
        // pub fn deinit()
    };
}

test ArenaBox {
    var d = try ArenaBox(u32).create(testing.allocator);
    defer d.deinitializer().deinit() catch {};

    d.value.* = 10;
}
