const std = @import("std");

const stdout = std.io.getStdOut().writer();

pub const TokenTag = enum {
    value,
    op_add,
    op_sub,
    op_mult,
    op_div,
    paren_open,
    paren_close,
};

pub const Token = union(TokenTag) {
    value: f64,
    op_add: void,
    op_sub: void,
    op_mult: void,
    op_div: void,
    paren_open: void,
    paren_close: void,

    pub fn print(self: Token) !void {
        return switch (self) {
            TokenTag.value => |value| try stdout.print("{d}", .{value}),
            TokenTag.op_add => try stdout.print("+", .{}),
            TokenTag.op_sub => try stdout.print("-", .{}),
            TokenTag.op_mult => try stdout.print("*", .{}),
            TokenTag.op_div => try stdout.print("/", .{}),
            TokenTag.paren_open => try stdout.print("(", .{}),
            TokenTag.paren_close => try stdout.print(")", .{}),
        };
    }
};
