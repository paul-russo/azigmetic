const std = @import("std");
const eql = std.mem.eql;

pub const reserved_words = [_][]const u8{ "quit", "exit", "vars", "variables", "results", "history" };

pub fn isReservedWord(word: []const u8) bool {
    for (reserved_words) |reserved_word| {
        if (eql(u8, word, reserved_word)) return true;
    }

    return false;
}
