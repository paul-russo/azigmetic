const std = @import("std");
const allocPrint = std.fmt.allocPrint;
const terseFloat = @import("cli.zig").terseFloat;

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
            STag.atom => |atom| try allocPrint(allocator, "{s}", .{terseFloat(allocator, atom)}),
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

pub fn makeCons(allocator: *std.mem.Allocator, head: u8, lhs: S, rhs: ?S) !S {
    var rest: []S = undefined;
    if (rhs != null) {
        rest = try allocator.alloc(S, 2);
    } else {
        rest = try allocator.alloc(S, 1);
    }

    rest[0] = lhs;
    if (rhs != null) rest[1] = rhs.?;

    return S{ .cons = .{ .head = head, .rest = rest } };
}
