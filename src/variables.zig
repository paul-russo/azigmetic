const std = @import("std");
const printTerseFloat = @import("cli.zig").printTerseFloat;

const stdout = std.io.getStdOut().writer();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var variableMap = std.StringArrayHashMap(f64).init(&gpa.allocator);

pub fn get(identifier: []const u8) ?f64 {
    return variableMap.get(identifier);
}

pub fn set(identifier: []const u8, value: f64) !void {
    // We need to copy over the identifier string to memory allocated by this module's allocator,
    // so it doesn't get freed by some other code.
    const copiedIdentifier = try std.fmt.allocPrint(&gpa.allocator, "{s}", .{identifier});
    try variableMap.put(copiedIdentifier, value);
}

pub fn print() !void {
    for (variableMap.keys()) |key| {
        var value = get(key) orelse 0;
        try stdout.print("{s}: ", .{key});
        try printTerseFloat(value);
        try stdout.print("\n", .{});
    }

    try stdout.print("\n", .{});
}
