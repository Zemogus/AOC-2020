const std = @import("std");
const data = @embedFile("18.txt");

const TermIterator = struct {
    buffer: []const u8,
    idx: usize,

    pub fn next(self: *TermIterator) ?[]const u8 {
        if (self.idx == self.buffer.len) {
            return null;
        }

        const start = self.idx;
        var end = self.idx + 1;

        if (self.buffer[start] == '(') {
            var depth: u32 = 1;
            while (true) : (end += 1) {
                if (depth == 0) {
                    break;
                }
                switch (self.buffer[end]) {
                    '(' => depth += 1,
                    ')' => depth -= 1,
                    else => {},
                }
            }
        } else {
            while (end < self.buffer.len and self.buffer[end] != ' ') : (end += 1) {}
        }

        self.idx = @min(end + 3, self.buffer.len);
        return self.buffer[start..end];
    }
};

fn splitTerms(expr: []const u8) TermIterator {
    return TermIterator{ .buffer = expr, .idx = 0 };
}

fn eval(expr: []const u8, precedence: bool) !u64 {
    var terms = splitTerms(expr);

    const left_str = terms.next().?;
    var result = if (left_str[0] == '(')
        try eval(left_str[1 .. left_str.len - 1], precedence)
    else
        try std.fmt.parseInt(u64, left_str, 10);

    var old_idx = terms.idx;
    while (terms.next()) |term| {
        const op = expr[old_idx - 2];
        switch (op) {
            '+' => result += try eval(term, precedence),
            '*' => {
                if (precedence) {
                    // Ordering between similar operations is not important
                    return result * try eval(expr[old_idx..], precedence);
                }
                result *= try eval(term, precedence);
            },
            else => unreachable,
        }
        old_idx = terms.idx;
    }

    return result;
}

pub fn part1() !u64 {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var sum: u64 = 0;
    while (lines.next()) |line| {
        sum += try eval(line, false);
    }
    return sum;
}

pub fn part2() !u64 {
    var lines = std.mem.tokenizeScalar(u8, data, '\n');
    var sum: u64 = 0;
    while (lines.next()) |line| {
        sum += try eval(line, true);
    }
    return sum;
}
