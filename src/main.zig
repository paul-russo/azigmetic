const std = @import("std");
const tokenizeInput = @import("./lexer.zig").tokenizeInput;

const stdout = std.io.getStdOut().writer();

pub fn main() anyerror!void {
    while (true) {
        var tokens = tokenizeInput() catch |err| {
            try stdout.print("Whoops: {s}\n", .{err});
            continue;
        };

        for (tokens) |token| {
            try token.print();
        }

        try stdout.print("\n", .{});
    }
}
