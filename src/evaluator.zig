const std = @import("std");
const S = @import("s.zig").S;
const math = @import("math.zig");
const variables = @import("variables.zig");

const EvaluatorError = error{
    InvalidExpression,
    UndefinedVariable,
};

pub fn evaluateExpression(expression: S) anyerror!f64 {
    if (expression == .atom) return expression.atom;
    if (expression == .identifier) {
        return variables.get(expression.identifier) orelse EvaluatorError.UndefinedVariable;
    }

    return switch (expression.cons.head) {
        // Always postfix
        '!' => blk: {
            const lhsResult = try evaluateExpression(expression.cons.rest[0]);

            break :blk try math.factorial(lhsResult);
        },

        // Both prefix and infix
        '+', '-' => |op| {
            var rhsResult: f64 = undefined;
            var lhsResult: f64 = undefined;

            // Check if this is prefix
            if (expression.cons.rest.len == 1) {
                lhsResult = 0;
                rhsResult = try evaluateExpression(expression.cons.rest[0]);
            } else {
                lhsResult = try evaluateExpression(expression.cons.rest[0]);
                rhsResult = try evaluateExpression(expression.cons.rest[1]);
            }

            return switch (op) {
                '+' => lhsResult + rhsResult,
                '-' => lhsResult - rhsResult,
                else => unreachable,
            };
        },

        // Always infix
        '/', '*', '^' => |op| {
            const lhsResult = try evaluateExpression(expression.cons.rest[0]);
            const rhsResult = try evaluateExpression(expression.cons.rest[1]);

            return switch (op) {
                '/' => lhsResult / rhsResult,
                '*' => lhsResult * rhsResult,
                '^' => math.exp(lhsResult, rhsResult),
                else => unreachable,
            };
        },

        // Always infix, right-associative
        '=' => {
            const lhs = expression.cons.rest[0];
            const rhsResult = try evaluateExpression(expression.cons.rest[1]);

            // If the left-hand side of an assignment expression isn't an identifier, then it's invalid.
            if (lhs != .identifier) return EvaluatorError.InvalidExpression;

            // Store the value
            try variables.set(lhs.identifier, rhsResult);

            return rhsResult;
        },
        else => EvaluatorError.InvalidExpression,
    };
}

// TESTS
test "expect result of (+ 1 (* 2 3)) to be 7" {
    const testExpression = S{
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

    const result = try evaluateExpression(testExpression);
    try std.testing.expectEqual(result, 7);
}

test "expect result of (+ (- (/ (* 64.2 1.5) 9.567) 4.3) 1.09) to be 7" {
    const testExpression = S{
        .cons = .{ .head = '+', .rest = &[_]S{
            S{ .cons = .{ .head = '-', .rest = &[_]S{
                S{ .cons = .{ .head = '/', .rest = &[_]S{
                    S{ .cons = .{ .head = '*', .rest = &[_]S{
                        S{ .atom = 64.2 },
                        S{ .atom = 1.5 },
                    } } },
                    S{ .atom = 9.567 },
                } } },
                S{ .atom = 4.3 },
            } } },
            S{ .atom = 1.09 },
        } },
    };

    const result = try evaluateExpression(testExpression);
    try std.testing.expectEqual(result, 6.85585136406397);
}

test "expect result of (+ (- 3.0) (- 6.0)) to be -9" {
    const testExpression = S{
        .cons = .{ .head = '+', .rest = &[_]S{
            S{ .cons = .{ .head = '-', .rest = &[_]S{S{ .atom = 3.0 }} } },
            S{ .cons = .{ .head = '-', .rest = &[_]S{S{ .atom = 6.0 }} } },
        } },
    };

    const result = try evaluateExpression(testExpression);
    try std.testing.expectEqual(result, -9.0);
}
