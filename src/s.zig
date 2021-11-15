const std = @import("std");
const stdout = std.io.getStdOut().writer();

pub const STag = enum {
    atom,
    cons,
};

pub const Cons = struct {
    head: u8,
    rest: []const S,
};

pub const S = union(STag) {
    atom: f64,
    cons: Cons,

    pub fn print(self: S) anyerror!void {
        switch (self) {
            STag.atom => |atom| try stdout.print("{d}", .{atom}),
            STag.cons => |cons| {
                try stdout.print("({c}", .{cons.head});

                for (cons.rest) |s| {
                    try stdout.print(" ", .{});
                    try s.print();
                }

                try stdout.print(")", .{});
            },
        }
    }
};
