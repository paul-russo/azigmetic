const std = @import("std");
const Token = @import("token.zig").Token;
const S = @import("s.zig").S;
const makeCons = @import("s.zig").makeCons;

const ParseError = error{
    UnexpectedEndOfInput,
    UnexpectedToken,
    UnexpectedOperation,
};

const InfixBp = struct {
    left: u8,
    right: u8,
};

// Get the left-and-right-side binding powers of the given infix operator.
fn getInfixBindingPower(op: u8) !?InfixBp {
    return switch (op) {
        '=' => .{ .left = 2, .right = 1 }, // right-associative
        '+', '-' => .{ .left = 3, .right = 4 }, // left-associative
        '*', '/', '%' => .{ .left = 5, .right = 6 }, // left-associative
        '^' => .{ .left = 8, .right = 7 }, // right-associative
        else => null,
    };
}

// Get the right-side binding power of the given prefix operator.
fn getPrefixBindingPower(op: u8) !u8 {
    return switch (op) {
        '+', '-' => 9,
        else => ParseError.UnexpectedOperation,
    };
}

// Get the left-side binding power of the given operator, provided it is postfix. Otherwise null.
fn getPostfixBindingPower(op: u8) ?u8 {
    return switch (op) {
        '!' => 11,
        else => null,
    };
}

var i: u64 = 0;

fn parseTokensBp(allocator: std.mem.Allocator, tokens: []const Token, min_bp: u8) anyerror!S {
    i += 1;

    var lhs = switch (tokens[i - 1]) {
        .value => |value| S{ .atom = value },
        .identifier => |identifier| S{ .identifier = identifier },
        .op => |op| blk: {
            if (op == '(') {
                const lhs = try parseTokensBp(allocator, tokens, 0);

                // Ensure the next operation is a closing paren
                i += 1;
                if (i >= tokens.len) return ParseError.UnexpectedEndOfInput;
                if (tokens[i - 1] != .op) return ParseError.UnexpectedToken;
                if (tokens[i - 1].op == ')') break :blk lhs;

                return ParseError.UnexpectedOperation;
            } else {
                const bp_right = try getPrefixBindingPower(op);
                const rhs = try parseTokensBp(allocator, tokens, bp_right);
                break :blk try makeCons(allocator, op, rhs, null);
            }
        },
        .eof => return ParseError.UnexpectedEndOfInput,
    };

    while (true) {
        const op = switch (tokens[i]) {
            .eof => break,
            .op => |op| op,
            .identifier, .value => return ParseError.UnexpectedToken,
        };

        const postfix_bp_left = getPostfixBindingPower(op);

        if (postfix_bp_left != null) {
            if (postfix_bp_left.? < min_bp) break;

            i += 1;

            lhs = try makeCons(allocator, op, lhs, null);
            continue;
        }

        const bp = try getInfixBindingPower(op);
        if (bp != null) {
            if (bp.?.left < min_bp) break;

            i += 1;

            const rhs = try parseTokensBp(allocator, tokens, bp.?.right);
            lhs = try makeCons(allocator, op, lhs, rhs);
            continue;
        }

        break;
    }

    return lhs;
}

pub fn parseTokens(allocator: std.mem.Allocator, tokens: []const Token) !S {
    i = 0;
    return parseTokensBp(allocator, tokens, 0);
}

// TESTS
test "expect parseTokens to return (+ 1 (* 2 3)) for 1 + 2 * 3" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const test_tokens = [_]Token{
        Token{ .value = 1.0 },
        Token{ .op = '+' },
        Token{ .value = 2.0 },
        Token{ .op = '*' },
        Token{ .value = 3.0 },
        Token{ .eof = undefined },
    };

    const expected_s = S{
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

    var expected_str = try expected_s.toString(&arena.allocator);

    var result_s = try parseTokens(&arena.allocator, test_tokens[0..]);
    var result_str = try result_s.toString(&arena.allocator);

    try std.testing.expect(std.mem.eql(u8, expected_str, result_str));
}

test "expect parseTokens to return (- 5) for -5" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const test_tokens = [_]Token{
        Token{ .op = '-' },
        Token{ .value = 5.0 },
        Token{ .eof = undefined },
    };

    const expected_s = S{
        .cons = .{
            .head = '-',
            .rest = &[_]S{
                S{ .atom = 5.0 },
            },
        },
    };

    var expected_str = try expected_s.toString(&arena.allocator);

    var result_s = try parseTokens(&arena.allocator, test_tokens[0..]);
    var result_str = try result_s.toString(&arena.allocator);

    try std.testing.expect(std.mem.eql(u8, expected_str, result_str));
}
