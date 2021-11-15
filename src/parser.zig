const std = @import("std");
const Token = @import("token.zig").Token;
const TokenTag = @import("token.zig").TokenTag;
const S = @import("s.zig").S;

const ParseError = error{
    UnsupportedOperation,
    UnsupportedToken,
};

const InfixBP = struct {
    left: u8,
    right: u8,
};

fn getInfixBindingPower(op: u8) !InfixBP {
    return switch (op) {
        '+', '-' => .{ .left = 1, .right = 2 },
        '*', '/' => .{ .left = 3, .right = 4 },
        else => ParseError.UnsupportedOperation,
    };
}

pub fn parseTokens(tokens: []const Token) !S {
    var lhs = switch (tokens[0]) {
        TokenTag.value => |value| S{ .atom = value },
        else => S{ .atom = 0 },
    };

    for (tokens) |token| {
        var op = switch (token) {
            TokenTag.eof => break,
            TokenTag.op => |op| op,
            TokenTag.value => continue,
        };

        var bp = try getInfixBindingPower(op);

        std.debug.print("{}", .{bp});
    }

    return lhs;
}

test "expect parseTokens to return (+ 1 (* 2 3)) for 1 + 2 * 3" {
    const testTokens = [_]Token{
        Token{ .value = 1.0 },
        Token{ .op = '+' },
        Token{ .value = 2.0 },
        Token{ .op = '*' },
        Token{ .value = 3.0 },
        Token{ .eof = undefined },
    };

    const expectedS = S{
        .cons = .{
            .head = '+',
            .rest = &[_]S{
                S{ .atom = 1.0 },
                S{
                    .cons = .{
                        .head = '*',
                        .rest = &[_]S{
                            S{ .atom = 2.0 },
                            S{ .atom = 3.0 },
                        },
                    },
                },
            },
        },
    };

    try std.testing.expectEqual(expectedS, try parseTokens(testTokens[0..]));
}
