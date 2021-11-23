const std = @import("std");
const tokenizeInput = @import("lexer.zig").tokenizeInput;
const parseTokens = @import("parser.zig").parseTokens;
const evaluateExpression = @import("evaluator.zig").evaluateExpression;

const stdout = std.io.getStdOut().writer();

pub fn main() anyerror!void {
    while (true) {
        // Initialize allocator, and defer deinitializing til the end of this loop.
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();

        var tokens = tokenizeInput() catch |err| {
            try stdout.print("tokenization error: {s}\n", .{err});
            continue;
        };

        var expression = parseTokens(tokens, &arena.allocator) catch |err| {
            try stdout.print("parse error: {s}\n", .{err});
            continue;
        };
        var expressionStr = try expression.to_string(&arena.allocator);
        try stdout.print("{s} = ", .{expressionStr});

        var result = evaluateExpression(expression) catch |err| {
            try stdout.print("evaluation error: {s}\n", .{err});
            continue;
        };
        try stdout.print("{d}\n", .{result});
    }
}
