const std = @import("std");
const allocPrint = std.fmt.allocPrint;

// Returns a stringified representation of the given float number,
// in scientific notation if the number is longer than 9 digits.
pub fn terseFloat(allocator: *std.mem.Allocator, x: f64) anyerror![]const u8 {
    const numDigits = @floor(@log10(x)) + 1;
    if (numDigits > 9 or numDigits < -9) {
        // Stringify with scientific notation
        return try allocPrint(allocator, "{}", .{x});
    }

    return try allocPrint(allocator, "{d}", .{x});
}
