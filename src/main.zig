const std = @import("std");
const htmlTokenizer = @import("html/tokenizer.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const rawHtml =
        \\<div class="container">
        \\    <h1>Welcome to the Site</h1>
        \\    <p>This is a paragraph.</p>
        \\</div>
    ;
    const tokens = htmlTokenizer.tokenize(allocator, rawHtml) catch undefined;
    for (tokens.items) |token| {
        std.debug.print("{}\n", .{token});
    }
}
