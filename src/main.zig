const std = @import("std");
const tokenizeInput = @import("lexer.zig").tokenizeInput;
const parseTokens = @import("parser.zig").parseTokens;

const stdout = std.io.getStdOut().writer();

pub fn main() anyerror!void {
    while (true) {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        var tokens = tokenizeInput() catch |err| {
            try stdout.print("tokenization error: {s}\n", .{err});
            continue;
        };

        for (tokens) |token| {
            try token.print();
        }

        var expression = parseTokens(tokens, &arena.allocator) catch |err| {
            try stdout.print("parse error: {s}\n", .{err});
            continue;
        };

        var expressionStr = try expression.to_string(&arena.allocator);
        try stdout.print("{s}\n", .{expressionStr});
    }
}
