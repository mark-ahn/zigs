const std = @import("std");

pub fn Writer(comptime C: type, comptime E: type, comptime methods: struct {
    write: fn (self: C, []const u8) E!usize,
}) type {
    return struct {
        const IFace = std.io.Writer(C, E, methods.write);
        pub const @"zigs.writer" = IFace;

        pub fn writer(self: C) IFace {
            return .{ .context = self };
        }
    };
}
pub fn Reader(comptime C: type, comptime E: type, comptime methods: struct {
    read: fn (self: C, []u8) E!usize,
}) type {
    return struct {
        const IFace = std.io.Reader(C, E, methods.read);
        pub const @"zigs.reader" = IFace;

        pub fn reader(self: C) IFace {
            return .{ .context = self };
        }
    };
}

test Writer {
    const local = struct {
        pub fn writerProxy(writer: anytype) WriterProxy(@TypeOf(writer)) {
            return .{ .writer = writer };
        }
        fn WriterProxy(comptime WriterT: type) type {
            return struct {
                writer: WriterT,
                const Context = @This();
                const Error = WriterT.Error || error{};
                pub usingnamespace Writer(Context, Error, .{
                    .write = write,
                });
                fn write(self: Context, buffer: []const u8) Error!usize {
                    return try self.writer.write(buffer);
                }
            };
        }

        const DebugProxy = struct {
            buffer: [13]u8 = "default value".*,

            const Context = @This();
            const Error = std.fs.File.ReadError || error{
                eof,
            };
            pub usingnamespace Writer(Context, Error, .{
                .write = write,
            });
            pub usingnamespace Reader(Context, Error, .{
                .read = read,
            });
            fn write(self: Context, buffer: []const u8) Error!usize {
                _ = self;
                std.debug.print("{s}", .{buffer});
                return buffer.len;
            }
            fn read(self: Context, buffer: []u8) Error!usize {
                const len = @min(buffer.len, self.buffer.len);
                std.mem.copy(u8, buffer[0..len], self.buffer[0..len]);
                if (self.buffer.len < buffer.len) return error.eof;
                // return std.io.getStdIn().read(buffer);
                return len;
            }
        };
    };

    {
        std.debug.print("\n", .{});
        var io = local.DebugProxy{};
        _ = try io.writer().write("debug?\n");
        var buffer: [2]u8 = undefined;
        _ = try io.reader().read(&buffer);
        _ = try io.writer().write(&buffer);
    }
}
