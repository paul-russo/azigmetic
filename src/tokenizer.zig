const std = @import("std");
const eql = std.mem.eql;
const Token = @import("token.zig").Token;
const variables = @import("variables.zig");

const stdin = std.io.getStdIn().reader();

var inputBuf: [1000]u8 = undefined;

var tokenIndex: u16 = 0;
var tokens: [1000]Token = undefined;

var currentValueIndex: u16 = 0;
var currentValue: [1000]u8 = undefined;

pub const TokenizeError = error{
    EmptyInput,
    CommandExecuted,
};

fn addValue(allocator: *std.mem.Allocator) !void {
    if (currentValueIndex == 0) return;

    const str = try std.fmt.allocPrint(allocator, "{s}", .{currentValue[0..currentValueIndex]});

    if (isCurrentValueIdentifier()) {
        tokens[tokenIndex] = Token{ .identifier = str };
    } else {
        var number = try std.fmt.parseFloat(f64, str);
        tokens[tokenIndex] = Token{ .value = number };
    }

    tokenIndex += 1;

    currentValue = undefined;
    currentValueIndex = 0;
}

fn addOp(char: u8) void {
    tokens[tokenIndex] = Token{ .op = char };
    tokenIndex += 1;
}

fn addEof() void {
    tokens[tokenIndex] = Token{ .eof = undefined };
    tokenIndex += 1;
}

fn isCurrentValueIdentifier() bool {
    if (currentValueIndex == 0) return false;

    return switch (currentValue[0]) {
        'A'...'Z', 'a'...'z', '_', '$' => true,
        else => false,
    };
}

pub fn tokenizeInput(allocator: *std.mem.Allocator) ![]const Token {
    inputBuf = undefined;

    tokenIndex = 0;
    tokens = undefined;

    currentValueIndex = 0;
    currentValue = undefined;

    if (try stdin.readUntilDelimiterOrEof(inputBuf[0..], '\n')) |chars| {
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

        // iterate over input array, creating tokens
        for (chars) |char| {
            switch (char) {
                ' ' => {
                    if (currentValueIndex > 0) try addValue(allocator);
                },

                '*', '/', '+', '-', '=', '!', '^', '(', ')' => {
                    if (currentValueIndex > 0) try addValue(allocator);
                    addOp(char);
                },

                '0'...'9', '.', 'A'...'Z', 'a'...'z', '_', '$' => {
                    currentValue[currentValueIndex] = char;
                    currentValueIndex += 1;
                },

                else => continue,
            }

            continue;
        }

        // Generate a token for any remaining characters
        if (currentValueIndex > 0) try addValue(allocator);

        // Add an EOF token, to indicate the end of input.
        addEof();
    }

    return tokens[0..tokenIndex];
}
