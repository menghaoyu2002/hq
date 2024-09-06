const std = @import("std");
const Token = std.zig.Token;
const Tag = Token.Tag;
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

pub fn tokenize(allocator: Allocator, rawHtml: [:0]const u8) !ArrayList(HTMLToken) {
    var tokenizer = std.zig.Tokenizer.init(rawHtml);
    var htmlTokens = ArrayList(HTMLToken).init(allocator);

    var token = tokenizer.next();
    while (token.tag != Tag.eof) {
        switch (token.tag) {
            .identifier => {
                const start = token.loc.start;
                var end = token.loc.end;

                var next = tokenizer.next();
                while (next.tag == Tag.identifier) : (next = tokenizer.next()) {
                    end = next.loc.end;
                }

                const content = rawHtml[start..end];
                switch (next.tag) {
                    .equal => {
                        const valueToken = tokenizer.next();
                        const value = rawHtml[valueToken.loc.start..valueToken.loc.end];
                        try htmlTokens.append(HTMLToken{ .attribute = .{ .key = content, .value = value } });
                    },
                    .angle_bracket_left => {
                        try htmlTokens.append(HTMLToken{ .text = content });
                        token = next; // cool line here. to avoid duplicating the code, just set the loop variable to the value and try again
                        continue;
                    },
                    else => {
                        try htmlTokens.append(HTMLToken{ .text = content });
                    },
                }
            },
            .angle_bracket_left => {
                var next = tokenizer.next();
                switch (next.tag) {
                    .slash => {
                        next = tokenizer.next();
                        const tag = rawHtml[next.loc.start..next.loc.end];
                        try htmlTokens.append(HTMLToken{ .endTag = tag });
                    },
                    .bang => {
                        // handle comments
                    },
                    else => {
                        const tag = rawHtml[next.loc.start..next.loc.end];
                        try htmlTokens.append(HTMLToken{ .startTag = tag });
                    },
                }
            },
            else => {}, // ignore other characters
        }
        token = tokenizer.next();
    }

    return htmlTokens;
}
