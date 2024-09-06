const std = @import("std");

const expect = std.testing.expect;
const ArrayList = std.ArrayList;
const mem = std.mem;
const Allocator = mem.Allocator;

const Attribute = struct { key: []const u8, value: []const u8 };

const HTMLToken = union(enum) {
    docType: []const u8,
    startTag: []const u8,
    endTag: []const u8,
    text: []const u8,
    comment: []const u8,
    attribute: Attribute,
};

const ReadResult = struct { []const u8, usize };

fn readTagName(str: []const u8) ReadResult {
    var i: usize = 0;
    while (i < str.len and str[i] != ' ' and str[i] != '>') : (i += 1) {}
    return .{ str[0..i], i };
}

fn readToEndOfTag(str: []const u8) ReadResult {
    var i: usize = 0;
    while (i < str.len and str[i] != '>') : (i += 1) {}
    return .{ str[0..i], i };
}

// fn readAttributes(str: []const u8) ReadResult {}

pub fn tokenize(allocator: Allocator, rawHtml: [:0]const u8) !ArrayList(HTMLToken) {
    var htmlTokens = ArrayList(HTMLToken).init(allocator);

    var i: usize = 0;
    while (i < rawHtml.len) : (i += 1) {
        const char = rawHtml[i];
        switch (char) {
            '<' => {
                // safe to assume +2 is sufficient. There cannot be an html tag with less than 3 characters
                if (i + 2 < rawHtml.len) {
                    switch (rawHtml[i + 1]) {
                        '/' => {
                            const tuple = readTagName(rawHtml[i + 2 ..]);
                            try htmlTokens.append(HTMLToken{ .endTag = tuple[0] });
                            i += tuple[1] + 2;
                        },
                        '!' => {
                            const tuple = readToEndOfTag(rawHtml[i + 2 ..]);
                            if (rawHtml[i + 2] == '-' and i + 3 < rawHtml.len and rawHtml[i + 3] == '-') {
                                const comment = tuple[0][3 .. tuple[0].len - 3];
                                try htmlTokens.append(HTMLToken{ .comment = comment });
                            } else {
                                try htmlTokens.append(HTMLToken{ .docType = tuple[0] });
                            }
                            i += tuple[1] + 2;
                        },
                        else => {
                            const tuple = readTagName(rawHtml[i + 1 ..]);
                            try htmlTokens.append(HTMLToken{ .startTag = tuple[0] });
                            i += tuple[1] + 1;
                        },
                    }
                }
            },
            else => {
                const start = i;
                var isAlphanumeric = false;
                while (i + 1 < rawHtml.len and rawHtml[i + 1] != '<') : (i += 1) {
                    isAlphanumeric = isAlphanumeric or std.ascii.isAlphanumeric(rawHtml[i]);
                }
                if (isAlphanumeric) {
                    try htmlTokens.append(HTMLToken{ .text = rawHtml[start .. i + 1] });
                }
            },
        }
    }

    return htmlTokens;
}
