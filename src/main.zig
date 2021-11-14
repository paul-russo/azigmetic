const std = @import("std");
const lexInput = @import("./lexer.zig").lexInput;

const stdout = std.io.getStdOut().writer();

pub fn main() anyerror!void {
    while (true) {
        var tokens = lexInput() catch |err| {
            try stdout.print("Whoops: {s}\n", .{err});
            continue;
        };

        for (tokens) |token| {
            try token.print();
        }

        try stdout.print("\n", .{});
    }
}
