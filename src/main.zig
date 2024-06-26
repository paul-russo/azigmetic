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
        var arena = std.heap.ArenaAllocator.init(gpa.allocator());
        const arena_allocator = arena.allocator();
        defer arena.deinit();

        // Tokenize the input, printing an error and continuing if something goes wrong.
        const tokens = tokenizeInput(arena_allocator) catch |err| {
            if (err != TokenizeError.EmptyInput and err != TokenizeError.CommandExecuted) {
                try stdout.print("tokenization error: {!}\n\n", .{err});
            }
            continue;
        };

        // Parse the tokens
        var expression = parseTokens(arena_allocator, tokens) catch |err| {
            try stdout.print("parse error: {!}\n\n", .{err});
            continue;
        };
        const expression_str = try expression.toString(arena_allocator);

        // Evaluate the parsed expression
        const result = evaluateExpression(expression) catch |err| {
            try stdout.print("evaluation error: {!}\n\n", .{err});
            continue;
        };

        // Store the result
        _ = try variables.addResult(result);

        try stdout.print("{s} = {s}\n\n", .{ expression_str, try terseFloat(arena_allocator, result) });
    }
}
