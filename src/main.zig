const std = @import("std");
const Token = @import("token.zig").Token;

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

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

fn addValueToken() !Token {
    var number = try getNumberFromArr(currentValue[0..currentValueIndex]);
    var token = Token{ .value = number };
    tokens[tokenIndex] = token;
    tokenIndex += 1;

    currentValue = undefined;
    currentValueIndex = 0;

    return token;
}

fn lexInput() ![]Token {
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
                        _ = try addValueToken();
                    }
                    continue;
                },

                '*' => {
                    if (currentValueIndex > 0) {
                        _ = try addValueToken();
                    }
                    tokens[tokenIndex] = Token{ .op_mult = undefined };
                    tokenIndex += 1;
                    continue;
                },

                '/' => {
                    if (currentValueIndex > 0) {
                        _ = try addValueToken();
                    }
                    tokens[tokenIndex] = Token{ .op_div = undefined };
                    tokenIndex += 1;
                    continue;
                },

                '+' => {
                    if (currentValueIndex > 0) {
                        _ = try addValueToken();
                    }
                    tokens[tokenIndex] = Token{ .op_add = undefined };
                    tokenIndex += 1;
                    continue;
                },

                '-' => {
                    if (currentValueIndex > 0) {
                        _ = try addValueToken();
                    }
                    tokens[tokenIndex] = Token{ .op_sub = undefined };
                    tokenIndex += 1;
                    continue;
                },

                '(' => {
                    if (currentValueIndex > 0) {
                        _ = try addValueToken();
                    }
                    tokens[tokenIndex] = Token{ .paren_open = undefined };
                    tokenIndex += 1;
                    continue;
                },

                ')' => {
                    if (currentValueIndex > 0) {
                        _ = try addValueToken();
                    }
                    tokens[tokenIndex] = Token{ .paren_close = undefined };
                    tokenIndex += 1;
                    continue;
                },

                else => {
                    currentValue[currentValueIndex] = char;
                    currentValueIndex += 1;
                    continue;
                },
            }
        }

        // Generate a token for any remaining characters
        if (currentValueIndex > 0) {
            _ = try addValueToken();
        }
    }

    return tokens[0..tokenIndex];
}

pub fn main() anyerror!void {
    while (true) {
        var result = try lexInput();

        for (result) |token| {
            try token.print();
        }

        try stdout.print("\n", .{});
    }
}
