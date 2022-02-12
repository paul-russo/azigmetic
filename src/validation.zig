const std = @import("std");
const eql = std.mem.eql;

pub const reservedWords = [_][]const u8{ "quit", "exit", "vars", "variables", "results", "history" };

pub fn isReservedWord(word: []const u8) bool {
    for (reservedWords) |reservedWord| {
        if (eql(u8, word, reservedWord)) return true;
    }

    return false;
}
