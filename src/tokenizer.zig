const std = @import("std");
const eql = std.mem.eql;
const Token = @import("token.zig").Token;

const stdin = std.io.getStdIn().reader();
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

var inputBuf: [1000]u8 = undefined;

var tokenIndex: u16 = 0;
var tokens: [1000]Token = undefined;

var currentValueIndex: u16 = 0;
var currentValue: [1000]u8 = undefined;

pub const TokenizeError = error{
    EmptyInput,
};

fn getNumberFromArr(arr: []u8) !f64 {
    const str = try std.fmt.allocPrint(&gpa.allocator, "{s}", .{arr});
    defer gpa.allocator.free(str);
    var number = try std.fmt.parseFloat(f64, str);
    return number;
}

fn addValue() !void {
    var number = try getNumberFromArr(currentValue[0..currentValueIndex]);
    tokens[tokenIndex] = Token{ .value = number };
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

pub fn tokenizeInput() ![]const Token {
    inputBuf = undefined;

    tokenIndex = 0;
    tokens = undefined;

    currentValueIndex = 0;
    currentValue = undefined;

    if (try stdin.readUntilDelimiterOrEof(inputBuf[0..], '\n')) |chars| {
        if (chars.len == 0) return TokenizeError.EmptyInput;
        if (eql(u8, chars, "quit") or eql(u8, chars, "exit")) std.process.exit(0);

        // iterate over input array, creating tokens
        for (chars) |char| {
            switch (char) {
                ' ' => {
                    if (currentValueIndex > 0) try addValue();
                    continue;
                },

                '*', '/', '+', '-', '(', ')' => {
                    if (currentValueIndex > 0) try addValue();
                    addOp(char);
                    continue;
                },

                '0'...'9', '.' => {
                    currentValue[currentValueIndex] = char;
                    currentValueIndex += 1;
                    continue;
                },

                else => {
                    continue;
                },
            }
        }

        // Generate a token for any remaining characters
        if (currentValueIndex > 0) try addValue();

        // Add an EOF token, to indicate the end of input.
        addEof();
    }

    return tokens[0..tokenIndex];
}
