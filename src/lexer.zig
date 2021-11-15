const std = @import("std");
const Token = @import("token.zig").Token;

const stdin = std.io.getStdIn().reader();

var buf: [1024]u8 = undefined;

var tokenIndex: u16 = 0;
var tokens: [1024]Token = undefined;

var currentValueIndex: u16 = 0;
var currentValue: [1024]u8 = undefined;

fn getNumberFromArr(arr: []u8) !f64 {
    const str = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{arr});
    var number = try std.fmt.parseFloat(f64, str);
    defer std.heap.page_allocator.free(str);
    return number;
}

fn addValue() !Token {
    var number = try getNumberFromArr(currentValue[0..currentValueIndex]);
    var token = Token{ .value = number };
    tokens[tokenIndex] = token;
    tokenIndex += 1;

    currentValue = undefined;
    currentValueIndex = 0;

    return token;
}

pub fn tokenizeInput() ![]Token {
    buf = undefined;

    tokenIndex = 0;
    tokens = undefined;

    currentValueIndex = 0;
    currentValue = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |chars| {
        // iterate over input array, creating tokens
        for (chars) |char| {
            switch (char) {
                ' ' => {
                    if (currentValueIndex > 0) {
                        _ = try addValue();
                    }
                    continue;
                },

                '*', '/', '+', '-', '(', ')' => {
                    if (currentValueIndex > 0) {
                        _ = try addValue();
                    }
                    tokens[tokenIndex] = Token{ .op = char };
                    tokenIndex += 1;
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
        if (currentValueIndex > 0) {
            _ = try addValue();
        }
    }

    return tokens[0..tokenIndex];
}