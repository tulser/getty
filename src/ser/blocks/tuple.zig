const std = @import("std");

const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .Struct and @typeInfo(T).Struct.is_tuple;
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

    var ss = try s.serializeSeq(std.meta.fields(T).len);
    const seq = ss.seq();
    inline for (@typeInfo(T).Struct.fields) |field| {
        try seq.serializeElement(@field(v, field.name));
    }
    return try seq.end();
}

test "serialize - tuple" {
    try t.run(null, serialize, .{}, &.{
        .{ .Seq = .{ .len = 0 } },
        .{ .SeqEnd = {} },
    });

    try t.run(null, serialize, std.meta.Tuple(&[_]type{ i32, bool }){ 1, true }, &.{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .Bool = true },
        .{ .SeqEnd = {} },
    });

    try t.run(null, serialize, .{ @as(i32, 1), true }, &.{
        .{ .Seq = .{ .len = 2 } },
        .{ .I32 = 1 },
        .{ .Bool = true },
        .{ .SeqEnd = {} },
    });
}
