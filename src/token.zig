const std = @import("std");
const allocPrint = std.fmt.allocPrint;

const stdout = std.io.getStdOut().writer();

pub const TokenTag = enum {
    identifier,
    value,
    op,
    eof,
};

pub const Token = union(TokenTag) {
    identifier: []const u8,
    value: f64,
    op: u8,
    eof: void,

    pub fn print(self: Token) !void {
        switch (self) {
            TokenTag.identifier => |identifier| try stdout.print("{s}", .{identifier}),
            TokenTag.value => |value| try stdout.print("{d}", .{value}),
            TokenTag.op => |op| try stdout.print("{c}", .{op}),
            TokenTag.eof => try stdout.print("\n", .{}),
        }
    }

    pub fn toString(self: Token, allocator: std.mem.Allocator) anyerror![]const u8 {
        return switch (self) {
            TokenTag.identifier => |identifier| try allocPrint(allocator, "{s}", .{identifier}),
            TokenTag.value => |value| try allocPrint(allocator, "{d}", .{value}),
            TokenTag.op => |op| try allocPrint(allocator, "{c}", .{op}),
            TokenTag.eof => "eof",
        };
    }
};
