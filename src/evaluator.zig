const std = @import("std");
const S = @import("s.zig").S;
const STag = @import("s.zig").STag;

const EvaluatorError = error{
    Wut,
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
        else => EvaluatorError.Wut,
    };
}
