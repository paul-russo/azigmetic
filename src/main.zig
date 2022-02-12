const std = @import("std");
const tokenizeInput = @import("tokenizer.zig").tokenizeInput;
const TokenizeError = @import("tokenizer.zig").TokenizeError;
const parseTokens = @import("parser.zig").parseTokens;
const evaluateExpression = @import("evaluator.zig").evaluateExpression;
const terseFloat = @import("cli.zig").terseFloat;
const variables = @import("variables.zig");

const stdout = std.io.getStdOut().writer();
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

pub fn main() anyerror!void {
    while (true) {
        // Initialize allocator, and defer deinitializing til the end of this loop.
        var arena = std.heap.ArenaAllocator.init(&gpa.allocator);
        defer arena.deinit();

        // Tokenize the input, printing an error and continuing if something goes wrong.
        var tokens = tokenizeInput(&arena.allocator) catch |err| {
            if (err != TokenizeError.EmptyInput) {
                try stdout.print("tokenization error: {s}\n\n", .{err});
            }
            continue;
        };

        // Parse the tokens
        var expression = parseTokens(&arena.allocator, tokens) catch |err| {
            try stdout.print("parse error: {s}\n\n", .{err});
            continue;
        };
        var expressionStr = try expression.to_string(&arena.allocator);

        // Evaluate the parsed expression
        var result = evaluateExpression(expression) catch |err| {
            try stdout.print("evaluation error: {s}\n\n", .{err});
            continue;
        };

        _ = try variables.addResult(result);

        try stdout.print("{s} = {s}\n\n", .{ expressionStr, terseFloat(&arena.allocator, result) });
    }
}
