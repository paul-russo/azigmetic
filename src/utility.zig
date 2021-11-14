const std = @import("std");

pub fn stringify(comptime T: type, value: T) ![]u8 {
    const str = try std.fmt.allocPrint(std.heap.page_allocator, "{s}", .{value});
    defer std.heap.page_allocator.free(str);
    return str;
}
