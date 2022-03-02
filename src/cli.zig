const std = @import("std");
const allocPrint = std.fmt.allocPrint;

const stdout = std.io.getStdOut().writer();

// Returns a stringified representation of the given float number,
// in scientific notation if the number is longer than 9 digits.
pub fn terseFloat(allocator: std.mem.Allocator, x: f64) ![]const u8 {
    const num_digits = @floor(@log10(x)) + 1;
    if (num_digits > 9 or num_digits < -9) {
        // Stringify with scientific notation
        return try allocPrint(allocator, "{}", .{x});
    }

    return try allocPrint(allocator, "{d}", .{x});
}

// Prints a stringified representation of the given float number,
// in scientific notation if the number is longer than 9 digits.
pub fn printTerseFloat(x: f64) !void {
    const num_digits = @floor(@log10(x)) + 1;
    if (num_digits > 9 or num_digits < -9) {
        // Stringify with scientific notation
        try stdout.print("{}", .{x});
    } else {
        try stdout.print("{d}", .{x});
    }
}
