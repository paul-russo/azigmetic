const std = @import("std");
const S = @import("s.zig").S;
const STag = @import("s.zig").STag;

const EvaluatorError = error{
    InvalidExpression,
    UndefinedVariable,
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var variableMap = std.StringHashMap(f64).init(&gpa.allocator);

pub fn evaluateExpression(expression: S) anyerror!f64 {
    if (expression == STag.atom) return expression.atom;
    if (expression == STag.identifier) {
        return variableMap.get(expression.identifier) orelse EvaluatorError.UndefinedVariable;
    }

    return switch (expression.cons.head) {
        '+', '-', '/', '*' => |op| {
            const lhsResult = try evaluateExpression(expression.cons.rest[0]);
            const rhsResult = try evaluateExpression(expression.cons.rest[1]);

            return switch (op) {
                '+' => lhsResult + rhsResult,
                '-' => lhsResult - rhsResult,
                '/' => lhsResult / rhsResult,
                '*' => lhsResult * rhsResult,
                else => EvaluatorError.InvalidExpression,
            };
        },
        '=' => {
            const lhs = expression.cons.rest[0];
            const rhsResult = try evaluateExpression(expression.cons.rest[1]);

            // If the left-hand side of an assignment expression isn't an identifier, then it's invalid.
            if (lhs != STag.identifier) return EvaluatorError.InvalidExpression;

            // We need to copy over the identifier string to memory allocated by this module's allocator,
            // so it doesn't get freed by some other code.
            const copiedIdentifier = try std.fmt.allocPrint(&gpa.allocator, "{s}", .{lhs.identifier});
            try variableMap.put(copiedIdentifier, rhsResult);

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
