const std = @import("std");
const Token = @import("token.zig").Token;
const S = @import("s.zig").S;

pub fn parseTokens(tokens: []const Token) S {
    // TODO
    std.debug.print("{s}", .{tokens});

    return S{ .atom = 2.0 };
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

    try std.testing.expectEqual(expectedS, parseTokens(testTokens[0..]));
}
