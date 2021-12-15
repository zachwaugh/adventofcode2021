const std = @import("std");
const mem = std.mem;
const math = std.math;
const fmt = std.fmt;
const ArrayList = std.ArrayList;
const Timer = std.time.Timer;
const utils = @import("utils.zig");
const Location = utils.Location;
const allocator = std.heap.page_allocator;
const print = @import("std").debug.print;

pub fn main() !void {
    const grid = try loadData("data/day15.txt");
    try puzzle1(grid);
    try puzzle2();
}

/// Answers
/// - Test: 40
/// - Input: 745
fn puzzle1(grid: [][]const u8) !void {
    var timer = try Timer.start();
    print("[Day 15/Puzzle 1] processing grid: {d}x{d}\n", .{ grid.len, grid[0].len });
    const risk = aStar(grid);
    print("[Day 15/Puzzle 1] lowest risk level: {d} in {d}\n", .{ risk, utils.seconds(timer.read()) });
}

fn puzzle2() !void {
    var timer = try Timer.start();
    print("[Day 15/Puzzle 2] not implemented in {d}\n", .{utils.seconds(timer.read())});
}

/// Ported almost verbatim from https://en.wikipedia.org/wiki/A*_search_algorithm
fn aStar(grid: [][]const u8) !?u32 {
    const start = Location.start();
    const max_score = std.math.maxInt(u32);

    var open_set = std.AutoHashMap(Location, void).init(allocator);
    defer open_set.deinit();
    try open_set.put(start, {});

    var paths = std.AutoHashMap(Location, Location).init(allocator);
    defer paths.deinit();

    var g_score = std.AutoHashMap(Location, u32).init(allocator);
    defer g_score.deinit();
    try g_score.put(start, 0);

    var f_score = std.AutoHashMap(Location, u32).init(allocator);
    defer f_score.deinit();
    try f_score.put(start, 0);

    while (open_set.count() > 0) {
        var current = findLowest(open_set, f_score);

        if (current.isEnd(grid)) {
            return riskLevel(paths, current, grid);
        }

        _ = open_set.remove(current);

        const neighbors = try current.neighbors(grid, allocator);
        for (neighbors) |neighbor| {
            const current_score = g_score.get(current) orelse max_score;
            const neighbor_score = g_score.get(neighbor) orelse max_score;
            const risk = grid[neighbor.row][neighbor.col];
            const tentative_gscore = current_score + risk;

            if (tentative_gscore < neighbor_score) {
                try paths.put(neighbor, current);
                try g_score.put(neighbor, tentative_gscore);
                try f_score.put(neighbor, tentative_gscore);
                try open_set.put(neighbor, {});
            }
        }
    }

    return null;
}

fn findLowest(set: std.AutoHashMap(Location, void), scores: std.AutoHashMap(Location, u32)) Location {
    var current: Location = undefined;
    var low_value: u32 = std.math.maxInt(u32);

    var iterator = set.keyIterator();
    while (iterator.next()) |key| {
        const location = key.*;
        if (scores.get(location)) |score| {
            if (score <= low_value) {
                low_value = score;
                current = location;
            }
        }
    }

    return current;
}

fn riskLevel(paths: std.AutoHashMap(Location, Location), current: Location, grid: [][]const u8) u32 {
    var risk_level: u32 = 0;
    var location: ?Location = current;

    while (location != null) {
        const value = grid[location.?.row][location.?.col];
        if (!location.?.isStart()) {
            risk_level += value;
        }

        location = paths.get(location.?);
    }

    return risk_level;
}

fn loadData(path: []const u8) ![][]const u8 {
    const lines = try utils.readLines(allocator, path);
    defer allocator.free(lines);
    var rows = ArrayList([]const u8).init(allocator);

    for (lines) |line| {
        var buffer = try allocator.alloc(u8, line.len);
        for (line) |character, index| {
            buffer[index] = try fmt.charToDigit(character, 10);
        }

        try rows.append(buffer);
    }

    return rows.toOwnedSlice();
}
