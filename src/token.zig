const std = @import("std");

const stdout = std.io.getStdOut().writer();

pub const TokenTag = enum {
    atom,
    op,
};

pub const Token = union(TokenTag) {
    atom: f64,
    op: u8,

    pub fn print(self: Token) !void {
        return switch (self) {
            TokenTag.atom => |atom| try stdout.print("{d}", .{atom}),
            TokenTag.op => |op| try stdout.print("{c}", .{op}),
        };
    }
};

pub const Expression = struct {
    factor: Factor,
    // +
    expression: ?Expression,
};

pub const Factor = struct {
    atom: Atom,
    // *
    factor: ?Factor,
};

pub const Atom = union {
    number: f64,
    // (
    expression: Expression,
    // )
};

// 5 + 3 * 2
const step1 = Atom{ .number = 5 }; // + 3 * 2
const step2 = Expression{ .factor{.atom{ .number = 5 }}, .expression{.factor{.atom{ .number = 3 }}} }; // * 2
const step3 = Expression{ .factor{.atom{ .number = 5 }}, .expression{.factor{ .atom{ .number = 3 }, .factor{.atom{ .number = 2 }} }} };
// (+ 5 ())

//   +
// 5  \
//    *
//   / \
//  3  2
