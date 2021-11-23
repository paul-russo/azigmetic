const std = @import("std");
const Token = @import("token.zig").Token;
const TokenTag = @import("token.zig").TokenTag;
const S = @import("s.zig").S;

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

const ParseError = error{
    UnsupportedOperation,
    UnsupportedToken,
};

const InfixBp = struct {
    left: u8,
    right: u8,
};

fn getInfixBindingPower(op: u8) !InfixBp {
    return switch (op) {
        '+', '-' => .{ .left = 1, .right = 2 },
        '*', '/' => .{ .left = 3, .right = 4 },
        else => ParseError.UnsupportedOperation,
    };
}

var i: u64 = 0;

fn parseTokensBp(tokens: []const Token, minBp: u8, allocator: *std.mem.Allocator) anyerror!S {
    var lhs = switch (tokens[i]) {
        TokenTag.value => |value| S{ .atom = value },
        else => return ParseError.UnsupportedOperation,
    };

    while (true) {
        var op = switch (tokens[i + 1]) {
            TokenTag.eof => {
                break;
            },
            TokenTag.op => |op| op,
            TokenTag.value => return ParseError.UnsupportedToken,
        };

        var bp = try getInfixBindingPower(op);

        if (bp.left < minBp) break;

        i += 2;

        var rhs = try parseTokensBp(tokens, bp.right, allocator);

        var rest = try allocator.alloc(S, 2);
        rest[0] = lhs;
        rest[1] = rhs;

        lhs = S{ .cons = .{ .head = op, .rest = rest } };
    }

    return lhs;
}

pub fn parseTokens(tokens: []const Token, allocator: *std.mem.Allocator) !S {
    i = 0;
    return parseTokensBp(tokens, 0, allocator);
}

test "expect parseTokens to return (+ 1 (* 2 3)) for 1 + 2 * 3" {
    defer arena.deinit();
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

    var expectedStr = try expectedS.to_string(&arena.allocator);
    std.debug.print("\n\nexpected: {s}\n\n", .{expectedStr});

    var resultS = try parseTokens(testTokens[0..], &arena.allocator);
    var resultStr = try resultS.to_string(&arena.allocator);
    std.debug.print("\n\nresult: {s}\n\n", .{resultStr});

    try std.testing.expect(std.mem.eql(u8, expectedStr, resultStr));
}
