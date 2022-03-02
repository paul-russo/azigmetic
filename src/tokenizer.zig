const std = @import("std");
const eql = std.mem.eql;
const Token = @import("token.zig").Token;
const variables = @import("variables.zig");

const stdin = std.io.getStdIn().reader();

var input_buf: [1000]u8 = undefined;

var token_index: u16 = 0;
var tokens: [1000]Token = undefined;

var current_value_index: u16 = 0;
var current_value: [1000]u8 = undefined;

pub const TokenizeError = error{
    EmptyInput,
    CommandExecuted,
};

fn addValue(allocator: std.mem.Allocator) !void {
    if (current_value_index == 0) return;

    const str = try std.fmt.allocPrint(allocator, "{s}", .{current_value[0..current_value_index]});

    if (isCurrentValueIdentifier()) {
        tokens[token_index] = Token{ .identifier = str };
    } else {
        var number = try std.fmt.parseFloat(f64, str);
        tokens[token_index] = Token{ .value = number };
    }

    token_index += 1;

    current_value = undefined;
    current_value_index = 0;
}

fn addOp(char: u8) void {
    tokens[token_index] = Token{ .op = char };
    token_index += 1;
}

fn addEof() void {
    tokens[token_index] = Token{ .eof = undefined };
    token_index += 1;
}

fn isCurrentValueIdentifier() bool {
    if (current_value_index == 0) return false;

    return switch (current_value[0]) {
        'A'...'Z', 'a'...'z', '$' => true,
        else => false,
    };
}

pub fn tokenizeInput(allocator: std.mem.Allocator) ![]const Token {
    input_buf = undefined;

    token_index = 0;
    tokens = undefined;

    current_value_index = 0;
    current_value = undefined;

    if (try stdin.readUntilDelimiterOrEof(input_buf[0..], '\n')) |chars| {
        if (chars.len == 0) return TokenizeError.EmptyInput;
        if (eql(u8, chars, "quit") or eql(u8, chars, "exit")) std.process.exit(0);

        if (eql(u8, chars, "vars") or eql(u8, chars, "variables")) {
            try variables.printVariables();
            return TokenizeError.CommandExecuted;
        }

        if (eql(u8, chars, "results")) {
            try variables.printResults();
            return TokenizeError.CommandExecuted;
        }

        if (eql(u8, chars, "history")) {
            try variables.printAll();
            return TokenizeError.CommandExecuted;
        }

        // iterate over input array, creating tokens
        for (chars) |char| {
            switch (char) {
                ' ' => {
                    if (current_value_index > 0) try addValue(allocator);
                },

                '*', '/', '+', '-', '=', '!', '^', '(', ')' => {
                    if (current_value_index > 0) try addValue(allocator);
                    addOp(char);
                },

                '0'...'9', '.', 'A'...'Z', 'a'...'z', '_', '$' => {
                    current_value[current_value_index] = char;
                    current_value_index += 1;
                },

                else => continue,
            }

            continue;
        }

        // Generate a token for any remaining characters
        if (current_value_index > 0) try addValue(allocator);

        // Add an EOF token, to indicate the end of input.
        addEof();
    }

    return tokens[0..token_index];
}
