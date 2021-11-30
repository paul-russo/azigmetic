const std = @import("std");
const allocPrint = std.fmt.allocPrint;

pub const STag = enum {
    identifier,
    atom,
    cons,
};

pub const Cons = struct {
    head: u8,
    rest: []const S,
};

pub const S = union(STag) {
    identifier: []const u8,
    atom: f64,
    cons: Cons,

    pub fn to_string(self: S, allocator: *std.mem.Allocator) anyerror![]const u8 {
        return switch (self) {
            STag.atom => |atom| try allocPrint(allocator, "{d}", .{atom}),
            STag.identifier => |identifier| try allocPrint(allocator, "{s}", .{identifier}),
            STag.cons => |cons| {
                var restStrings = cons.rest[0].to_string(allocator);

                for (cons.rest[1..]) |s| {
                    restStrings = try allocPrint(allocator, "{s} {s}", .{ restStrings, s.to_string(allocator) });
                }

                return try allocPrint(allocator, "({c} {s})", .{ cons.head, restStrings });
            },
        };
    }
};
