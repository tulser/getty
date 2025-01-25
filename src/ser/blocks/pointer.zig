//! `Pointer` is a _Serialization Block_ for pointer values.

const std = @import("std");

const getty_serialize = @import("../serialize.zig").serialize;
const t = @import("../testing.zig");

/// Specifies all types that can be serialized by this block.
pub fn is(
    /// The type of a value being serialized.
    comptime T: type,
) bool {
    return @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .one;
}

/// Specifies the serialization process for values relevant to this block.
pub fn serialize(
    /// An optional memory allocator.
    ally: ?std.mem.Allocator,
    /// A value being serialized.
    value: anytype,
    /// A `getty.Serializer` interface value.
    serializer: anytype,
) @TypeOf(serializer).Err!@TypeOf(serializer).Ok {
    const info = @typeInfo(@TypeOf(value)).pointer;

    // Serialize array pointers as slices so that strings are handled properly.
    if (@typeInfo(info.child) == .array) {
        const Slice = []const std.meta.Elem(info.child);
        return try getty_serialize(ally, @as(Slice, value), serializer);
    }

    return try getty_serialize(ally, value.*, serializer);
}

test "serialize - pointer" {
    // one level of indirection
    {
        const ptr = try std.testing.allocator.create(i32);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = @as(i32, 1);

        try t.run(null, serialize, ptr, &.{.{ .I32 = 1 }});
    }

    // two levels of indirection
    {
        const tmp = try std.testing.allocator.create(i32);
        defer std.testing.allocator.destroy(tmp);
        tmp.* = 2;

        const ptr = try std.testing.allocator.create(*i32);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = tmp;

        try t.run(null, serialize, ptr, &.{.{ .I32 = 2 }});
    }

    // pointer to slice
    {
        const ptr = try std.testing.allocator.create([]const u8);
        defer std.testing.allocator.destroy(ptr);
        ptr.* = "3";

        try t.run(null, serialize, ptr, &.{.{ .String = "3" }});
    }
}
