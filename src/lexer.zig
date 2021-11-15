const std = @import("std");
const Token = @import("token.zig").Token;

const stdin = std.io.getStdIn().reader();

var buf: [1024]u8 = undefined;

var tokenIndex: u16 = 0;
var tokens: [1024]Token = undefined;

var currentAtomIndex: u16 = 0;
var currentAtom: [1024]u8 = undefined;

fn getNumberFromArr(arr: []u8) !f64 {
    const str = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{arr});
    var number = try std.fmt.parseFloat(f64, str);
    defer std.heap.page_allocator.free(str);
    return number;
}

fn addAtom() !Token {
    var number = try getNumberFromArr(currentAtom[0..currentAtomIndex]);
    var token = Token{ .atom = number };
    tokens[tokenIndex] = token;
    tokenIndex += 1;

    currentAtom = undefined;
    currentAtomIndex = 0;

    return token;
}

pub fn tokenizeInput() ![]Token {
    buf = undefined;

    tokenIndex = 0;
    tokens = undefined;

    currentAtomIndex = 0;
    currentAtom = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |chars| {
        // iterate over input array, creating tokens
        for (chars) |char| {
            switch (char) {
                ' ' => {
                    if (currentAtomIndex > 0) {
                        _ = try addAtom();
                    }
                    continue;
                },

                '*', '/', '+', '-', '(', ')' => {
                    if (currentAtomIndex > 0) {
                        _ = try addAtom();
                    }
                    tokens[tokenIndex] = Token{ .op = char };
                    tokenIndex += 1;
                    continue;
                },

                '0'...'9', '.' => {
                    currentAtom[currentAtomIndex] = char;
                    currentAtomIndex += 1;
                    continue;
                },

                else => {
                    continue;
                },
            }
        }

        // Generate a token for any remaining characters
        if (currentAtomIndex > 0) {
            _ = try addAtom();
        }
    }

    return tokens[0..tokenIndex];
}
