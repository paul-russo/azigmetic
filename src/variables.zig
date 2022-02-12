const std = @import("std");
const printTerseFloat = @import("cli.zig").printTerseFloat;

const stdout = std.io.getStdOut().writer();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var variableMap = std.StringArrayHashMap(f64).init(&gpa.allocator);
var resultIndex: u64 = 0;

pub fn get(identifier: []const u8) ?f64 {
    return variableMap.get(identifier);
}

pub fn set(identifier: []const u8, value: f64) !void {
    // We need to copy over the identifier string to memory allocated by this module's allocator,
    // so it doesn't get freed by some other code.
    const copiedIdentifier = try std.fmt.allocPrint(&gpa.allocator, "{s}", .{identifier});
    try variableMap.put(copiedIdentifier, value);
}

pub fn addResult(value: f64) !u64 {
    resultIndex += 1;
    const resultIdentifier = try std.fmt.allocPrint(&gpa.allocator, "${d}", .{resultIndex});
    try variableMap.put(resultIdentifier, value);

    return resultIndex;
}

pub fn print(includeVars: bool, includeResults: bool) !void {
    for (variableMap.keys()) |key| {
        if (!includeResults and key[0] == '$') continue;
        if (!includeVars and key[0] != '$') continue;

        var value = get(key) orelse 0;
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
