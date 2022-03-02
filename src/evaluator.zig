const std = @import("std");
const eql = std.mem.eql;
const S = @import("s.zig").S;
const math = @import("math.zig");
const variables = @import("variables.zig");
const validation = @import("validation.zig");

const EvaluatorError = error{
    InvalidExpression,
    UndefinedVariable,
    CannotAssignToResult,
    CannotAssignToReservedWord,
};

pub fn evaluateExpression(expression: S) anyerror!f64 {
    if (expression == .atom) return expression.atom;
    if (expression == .identifier) {
        return variables.get(expression.identifier) orelse EvaluatorError.UndefinedVariable;
    }

    return switch (expression.cons.head) {
        // Always postfix
        '!' => blk: {
            const lhs_result = try evaluateExpression(expression.cons.rest[0]);

            break :blk try math.factorial(lhs_result);
        },

        // Both prefix and infix
        '+', '-' => |op| {
            var rhs_result: f64 = undefined;
            var lhs_result: f64 = undefined;

            // Check if this is prefix
            if (expression.cons.rest.len == 1) {
                lhs_result = 0;
                rhs_result = try evaluateExpression(expression.cons.rest[0]);
            } else {
                lhs_result = try evaluateExpression(expression.cons.rest[0]);
                rhs_result = try evaluateExpression(expression.cons.rest[1]);
            }

            return switch (op) {
                '+' => lhs_result + rhs_result,
                '-' => lhs_result - rhs_result,
                else => unreachable,
            };
        },

        // Always infix
        '/', '*', '%', '^' => |op| {
            const lhs_result = try evaluateExpression(expression.cons.rest[0]);
            const rhs_result = try evaluateExpression(expression.cons.rest[1]);

            return switch (op) {
                '/' => lhs_result / rhs_result,
                '*' => lhs_result * rhs_result,
                '%' => std.math.mod(f64, lhs_result, rhs_result),
                '^' => math.exp(lhs_result, rhs_result),
                else => unreachable,
            };
        },

        // Always infix, right-associative
        '=' => {
            const lhs = expression.cons.rest[0];
            const rhs_result = try evaluateExpression(expression.cons.rest[1]);

            // If the left-hand side of an assignment expression isn't an identifier, then it's invalid.
            if (lhs != .identifier) return EvaluatorError.InvalidExpression;
            if (lhs.identifier[0] == '$') return EvaluatorError.CannotAssignToResult;
            if (validation.isReservedWord(lhs.identifier)) return EvaluatorError.CannotAssignToReservedWord;

            // Store the value
            try variables.set(lhs.identifier, rhs_result);

            return rhs_result;
        },
        else => EvaluatorError.InvalidExpression,
    };
}

// TESTS
test "expect result of (+ 1 (* 2 3)) to be 7" {
    const test_expression = S{
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

    const result = try evaluateExpression(test_expression);
    try std.testing.expectEqual(result, 7);
}

test "expect result of (+ (- (/ (* 64.2 1.5) 9.567) 4.3) 1.09) to be 7" {
    const test_expression = S{
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

    const result = try evaluateExpression(test_expression);
    try std.testing.expectEqual(result, 6.85585136406397);
}

test "expect result of (+ (- 3.0) (- 6.0)) to be -9" {
    const test_expression = S{
        .cons = .{ .head = '+', .rest = &[_]S{
            S{ .cons = .{ .head = '-', .rest = &[_]S{S{ .atom = 3.0 }} } },
            S{ .cons = .{ .head = '-', .rest = &[_]S{S{ .atom = 6.0 }} } },
        } },
    };

    const result = try evaluateExpression(test_expression);
    try std.testing.expectEqual(result, -9.0);
}
