const std = @import("std");
const tokenizeInput = @import("tokenizer.zig").tokenizeInput;
const TokenizeError = @import("tokenizer.zig").TokenizeError;
const parseTokens = @import("parser.zig").parseTokens;
const evaluateExpression = @import("evaluator.zig").evaluateExpression;

const stdout = std.io.getStdOut().writer();
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() anyerror!void {
    defer _ = gpa.deinit();

    while (true) {
        // Initialize allocator, and defer deinitializing til the end of this loop.
        var arena = std.heap.ArenaAllocator.init(&gpa.allocator);
        defer arena.deinit();

        // Tokenize the input, printing an error and continuing if something goes wrong.
        var tokens = tokenizeInput(&arena.allocator) catch |err| {
            if (err != TokenizeError.EmptyInput) {
                try stdout.print("tokenization error: {s}\n", .{err});
            }
            continue;
        };

        for (tokens) |token| {
            try token.print();
        }

        // Parse the tokens
        var expression = parseTokens(&arena.allocator, tokens) catch |err| {
            try stdout.print("parse error: {s}\n", .{err});
            continue;
        };
        var expressionStr = try expression.to_string(&arena.allocator);
        try stdout.print("{s} = ", .{expressionStr});

        // Evaluate the parsed expression
        var result = evaluateExpression(expression) catch |err| {
            try stdout.print("evaluation error: {s}\n", .{err});
            continue;
        };
        try stdout.print("{d}\n\n", .{result});
    }
}
