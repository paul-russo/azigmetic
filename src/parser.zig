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

// Get the left-and-right-side binding powers of the given infix operator.
fn getInfixBindingPower(op: u8) !InfixBp {
    return switch (op) {
        '=' => .{ .left = 2, .right = 1 },
        '+', '-' => .{ .left = 3, .right = 4 },
        '*', '/' => .{ .left = 5, .right = 6 },
        else => ParseError.UnsupportedOperation,
    };
}

// Get the right-side binding power of the given prefix operator.
fn getPrefixBindingPower(op: u8) !u8 {
    return switch (op) {
        '+', '-' => 7,
        else => ParseError.UnsupportedOperation,
    };
}

// Get the left-side binding power of the given operator, provided it is postfix. Otherwise null.
fn getPostfixBindingPower(op: u8) ?u8 {
    return switch (op) {
        '!' => 9,
        else => null,
    };
}

var i: u64 = 0;

fn parseTokensBp(allocator: *std.mem.Allocator, tokens: []const Token, minBp: u8) anyerror!S {
    i += 1;

    var lhs = switch (tokens[i - 1]) {
        TokenTag.value => |value| S{ .atom = value },
        TokenTag.identifier => |identifier| S{ .identifier = identifier },
        TokenTag.op => |op| blk: {
            const bpRight = try getPrefixBindingPower(op);
            const rhs = try parseTokensBp(allocator, tokens, bpRight);
            break :blk try makeCons(allocator, op, rhs, null);
        },
        else => return ParseError.UnsupportedToken,
    };

    while (true) {
        const op = switch (tokens[i]) {
            TokenTag.eof => break,
            TokenTag.op => |op| op,
            TokenTag.identifier, TokenTag.value => return ParseError.UnsupportedOperation,
        };

        const postfixBpLeft = getPostfixBindingPower(op);

        if (postfixBpLeft != null) {
            if (postfixBpLeft.? < minBp) break;

            i += 1;

            lhs = try makeCons(allocator, op, lhs, null);
            continue;
        }

        const bp = try getInfixBindingPower(op);
        if (bp.left < minBp) break;

        i += 1;

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

test "expect parseTokens to return (- 5) for -5" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const testTokens = [_]Token{
        Token{ .op = '-' },
        Token{ .value = 5.0 },
        Token{ .eof = undefined },
    };

    const expectedS = S{
        .cons = .{
            .head = '-',
            .rest = &[_]S{
                S{ .atom = 5.0 },
            },
        },
    };

    var expectedStr = try expectedS.to_string(&arena.allocator);

    var resultS = try parseTokens(&arena.allocator, testTokens[0..]);
    var resultStr = try resultS.to_string(&arena.allocator);

    try std.testing.expect(std.mem.eql(u8, expectedStr, resultStr));
}
