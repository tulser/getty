const std = @import("std");
const attr = @import("detail/attribute.zig");

pub fn Serialize(comptime T: type, attr_map: anytype) type {
    attr.check_attributes(T, attr_map, .Ser);

    return struct {
        pub fn serialize(self: T) !void {
            std.debug.print("Serialize!\n", .{});
        }
    };
}

test "Basic" {
    const Test = struct {
        usingnamespace Serialize(
            @This(),
            .{
                .Test = .{ .rename = "Foo" },
                .x = .{ .rename = "a" },
                .y = .{ .rename = "b" },
            },
        );

        x: i32,
        y: i32,
    };
}
