const std = @import("std");

const MathError = error{
    FactorialOfNonPositiveInteger,
};

// Takes a floating-point number, attempts to safely cast it to integer, and then
// computes the factorial of the integer before casting back to floating-point.
pub fn factorial(x: f64) MathError!f64 {
    // The factorial of a negative integer is not defined.
    if (x < 0.0) return MathError.FactorialOfNonPositiveInteger;
    // If the remainder of x/1 isn't 0, then this isn't an integer.
    if (@mod(x, 1.0) != 0.0) return MathError.FactorialOfNonPositiveInteger;

    var xI = @floatToInt(u64, x);
    var product: u64 = 1;

    while (xI > 0) : (xI -= 1) {
        product = product * xI;
    }

    return @intToFloat(f64, product);
}

test "expect factorial to compute that 5! is 120." {
    const result = try factorial(5);
    try std.testing.expectEqual(@as(f64, 120.0), result);
}
