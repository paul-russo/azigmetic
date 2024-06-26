const std = @import("std");

const MathError = error{
    FactorialOfNonPositiveInteger,
    ExponentiationOfNegativeByNonInteger,
};

// Takes a floating-point number, attempts to safely cast it to integer, and then
// computes the factorial of the integer before casting back to floating-point.
pub fn factorial(x: f64) MathError!f64 {
    // The factorial of a negative integer is not defined.
    if (x < 0.0) return MathError.FactorialOfNonPositiveInteger;

    // If the remainder of x/1 isn't 0, then this isn't an integer.
    if (@mod(x, 1.0) != 0.0) return MathError.FactorialOfNonPositiveInteger;

    // 171! is greater than the maximum finite value of f64, so we can short-
    // circuit here and return the infinite value for f64.
    if (x > 170) return std.math.inf(f64);

    // Copy argument to a local variable.
    var y = x;
    var product: f64 = 1;

    while (y > 0) : (y -= 1) {
        product = product * y;
    }

    return product;
}

test "expect factorial to compute that 5! is 120." {
    const result = try factorial(5);
    try std.testing.expectEqual(@as(f64, 120.0), result);
}

test "expect factorial to safely avoid computing absurdly large factorials." {
    const result = try factorial(200);
    try std.testing.expectEqual(std.math.inf(f64), result);
}

// Takes a base x and an exponent n and calculates x^n.
pub fn exp(x: f64, n: f64) MathError!f64 {
    // If the base is negative, and the exponent isn't a whole number, then the result
    // is Imaginary. We live in the Real world here, so return an error instead.
    if (x < 0 and @mod(n, 1.0) != 0.0) return MathError.ExponentiationOfNegativeByNonInteger;

    var abs_result = @exp(n * @log(@abs(x)));

    // If both the base and the exponent are whole numbers (and the exponent is positive),
    // we know the result should be a whole number, so round to the nearest one.
    // (this is kludgy)
    if (n > 0 and @mod(n, 1.0) == 0.0 and @mod(x, 1.0) == 0.0) {
        abs_result = @round(abs_result);
    }

    // If the base is negative, and the exponent is odd, then the result is negative.
    // Otherwise, it's positive, as -x * -x = x * x.
    if (x < 0 and @mod(n, 2.0) == 1.0) return -abs_result;
    return abs_result;
}

test "expect exp to compute that 5^2 is 25." {
    const result = try exp(5, 2);
    try std.testing.expectEqual(@as(f64, 25.0), result);
}

test "expect exp to compute that -5^2 is 25." {
    const result = try exp(-5, 2);
    try std.testing.expectEqual(@as(f64, 25.0), result);
}

test "expect exp to compute that -5^3 is -125." {
    const result = try exp(-5, 3);
    try std.testing.expectEqual(@as(f64, -125.0), result);
}
