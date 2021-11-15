const std = @import("std");

const stdout = std.io.getStdOut().writer();

pub const TokenTag = enum {
    value,
    op,
    eof,
};

pub const Token = union(TokenTag) {
    value: f64,
    op: u8,
    eof: void,

    pub fn print(self: Token) !void {
        return switch (self) {
            TokenTag.value => |value| try stdout.print("{d}", .{value}),
            TokenTag.op => |op| try stdout.print("{c}", .{op}),
            TokenTag.eof => try stdout.print("\n", .{}),
        };
    }
};
