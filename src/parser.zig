const std = @import("std");
const Token = @import("token.zig").Token;
const TokenTag = @import("token.zig").TokenTag;
const S = @import("s.zig").S;
const makeCons = @import("s.zig").makeCons;

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
        '=' => .{ .left = 1, .right = 2 },
        '+', '-' => .{ .left = 3, .right = 4 },
        '*', '/' => .{ .left = 5, .right = 6 },
        else => ParseError.UnsupportedOperation,
    };
}

fn getPrefixBindingPower(op: u8) !u8 {
    return switch (op) {
        '+', '-' => 7,
        else => ParseError.UnsupportedOperation,
    };
}

var i: u64 = 0;

fn parseTokensBp(allocator: *std.mem.Allocator, tokens: []const Token, minBp: u8) anyerror!S {
    var lhs = switch (tokens[i]) {
        TokenTag.value => |value| S{ .atom = value },
        TokenTag.identifier => |identifier| S{ .identifier = identifier },
        TokenTag.op => |op| {
            const bpRight = try getPrefixBindingPower(op);
            const rhs = try parseTokensBp(allocator, tokens, bpRight);
            return try makeCons(allocator, op, rhs, null);
        },
        else => return ParseError.UnsupportedToken,
    };

    while (true) {
        const op = switch (tokens[i + 1]) {
            TokenTag.eof => break,
            TokenTag.op => |op| op,
            TokenTag.identifier, TokenTag.value => return ParseError.UnsupportedOperation,
        };

        const bp = try getInfixBindingPower(op);
        if (bp.left < minBp) break;

        i += 2;

        const rhs = try parseTokensBp(allocator, tokens, bp.right);
        lhs = try makeCons(allocator, op, lhs, rhs);
    }

    return lhs;
}

pub fn parseTokens(allocator: *std.mem.Allocator, tokens: []const Token) !S {
    i = 0;
    return parseTokensBp(allocator, tokens, 0);
}

// TESTS
test "expect parseTokens to return (+ 1 (* 2 3)) for 1 + 2 * 3" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
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

    var resultS = try parseTokens(&arena.allocator, testTokens[0..]);
    var resultStr = try resultS.to_string(&arena.allocator);

    try std.testing.expect(std.mem.eql(u8, expectedStr, resultStr));
}
