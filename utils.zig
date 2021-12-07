const std = @import("std");
const mem = std.mem;
const fs = std.fs;

/// Read a file into an array of strings, each representing a line in the file
pub fn readLines(allocator: *mem.Allocator, path: []const u8) ![][]const u8 {
    const input = try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
    defer allocator.free(input);

    var list = std.ArrayList([]const u8).init(allocator);

    var iterator = mem.tokenize(u8, input, "\n");
    while (iterator.next()) |value| {
        try list.append(try allocator.dupe(u8, value));
    }

    return list.toOwnedSlice();
}

test "read lines" {
    const allocator = std.testing.allocator;
    const lines = try readLines(allocator, "test/lines.txt");
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
        allocator.free(lines);
    }

    try std.testing.expect(lines.len == 3);
    try std.testing.expect(std.mem.eql(u8, lines[0], "line1") == true);
}

pub fn loadData(comptime T: type, allocator: *std.mem.Allocator, path: []const u8) ![]const T {
    const lines = try readLines(allocator, path);
    defer allocator.free(lines);
    std.debug.assert(lines.len == 1);
    return parseNumberLine(T, allocator, lines[0]);
}

/// Parse a single line of comma-separated numbers into array
pub fn parseNumberLine(comptime T: type, allocator: *std.mem.Allocator, line: []const u8) ![]const T {
    var tokens = mem.split(u8, line, ",");
    var numbers = std.ArrayList(T).init(allocator);
    defer numbers.deinit();

    while (tokens.next()) |token| {
        const number = try std.fmt.parseInt(T, token, 10);
        try numbers.append(number);
    }

    return numbers.toOwnedSlice();
}

/// Sum an array of integers
pub fn sum(array: []const u32) u32 {
    var result: u32 = 0;
    for (array) |value| {
        result += value;
    }

    return result;
}

test "sum" {
    const numbers = [_]u32{ 1, 2, 3, 4, 5 };
    const total = sum(&numbers);

    try std.testing.expect(total == 15);
}

/// Average of array of numbers
pub fn average(array: []const u32) u32 {
    const total = sum(array);
    return total / @intCast(u32, array.len);
}

pub fn min(array: []const u32) u32 {
    if (array.len == 0) return 0;

    var minimum: u32 = array[0];

    for (array) |number| {
        if (number < minimum) {
            minimum = number;
        }
    }

    return minimum;
}

test "min" {
    const array = [_]u32{ 4, 100, 5, 20, 2, 1, 8, 50 };
    try std.testing.expect(min(&array) == 1);
}

pub fn max(array: []const u32) u32 {
    if (array.len == 0) return 0;

    var maximum: u32 = array[0];

    for (array) |number| {
        if (number > maximum) {
            maximum = number;
        }
    }

    return maximum;
}

test "max" {
    const array = [_]u32{ 4, 100, 5, 20, 2, 1, 8, 50 };
    try std.testing.expect(max(&array) == 100);
}
