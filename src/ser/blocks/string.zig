const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return comptime std.meta.trait.isZigString(T);
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    v: anytype,
    /// A `getty.Serializer` interface value.
    s: anytype,
) @TypeOf(s).Err!@TypeOf(s).Ok {
    _ = ally;

    const T = @TypeOf(v);

    comptime std.debug.assert(std.meta.trait.isZigString(T));

    // If there is a sentinel value, avoid serializing anything after it.
    if (comptime std.meta.sentinel(T)) |sentinel| {
        const i = std.mem.indexOfSentinel(u8, sentinel, v);
        return try s.serializeString(v[0..i]);
    }

    return try s.serializeString(v);
}

test "serialize - string" {
    try t.run(null, serialize, "abc", &.{.{ .String = "abc" }});
    try t.run(null, serialize, &[_]u8{ 'a', 'b', 'c' }, &.{.{ .String = "abc" }});
    try t.run(null, serialize, &[_:0]u8{ 'a', 'b', 'c' }, &.{.{ .String = "abc" }});
    try t.run(null, serialize, &[_:0]u8{ 'a', 'b', 'c', 0, 0xAA, 0xAA }, &.{.{ .String = "abc" }});
}
