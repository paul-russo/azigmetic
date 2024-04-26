const std = @import("std");
const printTerseFloat = @import("cli.zig").printTerseFloat;

const stdout = std.io.getStdOut().writer();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpa_allocator = gpa.allocator();
var variables = std.StringArrayHashMap(f64).init(gpa.allocator());
var result_index: u64 = 0;

pub fn get(identifier: []const u8) ?f64 {
    return variables.get(identifier);
}

pub fn set(identifier: []const u8, value: f64) !void {
    // We need to copy over the identifier string to memory allocated by this module's allocator,
    // so it doesn't get freed by some other code.
    const identifier_copied = try std.fmt.allocPrint(gpa_allocator, "{s}", .{identifier});
    try variables.put(identifier_copied, value);
}

pub fn addResult(value: f64) !u64 {
    result_index += 1;
    const result_identifier = try std.fmt.allocPrint(gpa_allocator, "${d}", .{result_index});
    try variables.put(result_identifier, value);

    return result_index;
}

pub fn print(includeVars: bool, includeResults: bool) !void {
    for (variables.keys()) |key| {
        if (!includeResults and key[0] == '$') continue;
        if (!includeVars and key[0] != '$') continue;

        const value = get(key) orelse 0;
        try stdout.print("{s}: ", .{key});
        try printTerseFloat(value);
        try stdout.print("\n", .{});
    }

    try stdout.print("\n", .{});
}

pub fn printVariables() !void {
    return print(true, false);
}

pub fn printResults() !void {
    return print(false, true);
}

pub fn printAll() !void {
    return print(true, true);
}
