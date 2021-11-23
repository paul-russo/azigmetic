const std = @import("std");
const S = @import("s.zig").S;
const STag = @import("s.zig").STag;

const EvaluatorError = error{
    InvalidExpression,
};

pub fn evaluateExpression(expression: S) EvaluatorError!f64 {
    if (expression == STag.atom) return expression.atom;

    var lhs = try evaluateExpression(expression.cons.rest[0]);
    var rhs = try evaluateExpression(expression.cons.rest[1]);

    return switch (expression.cons.head) {
        '+' => lhs + rhs,
        '-' => lhs - rhs,
        '/' => lhs / rhs,
        '*' => lhs * rhs,
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

    var result = try evaluateExpression(testExpression);
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

    var result = try evaluateExpression(testExpression);
    try std.testing.expectEqual(result, 6.85585136406397);
}
