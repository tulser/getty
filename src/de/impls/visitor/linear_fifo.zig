const std = @import("std");

const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime LinearFifo: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = LinearFifo;

        fn visitSeq(_: Self, ally: std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Err!Value {
            if (is_buffer_static) {
                var fifo = Value.init();
                errdefer fifo.deinit();

                for (0..fifo.buf.len) |_| {
                    if (try seq.nextElement(ally, Child)) |elem| {
                        fifo.writeItemAssumeCapacity(elem);
                    } else {
                        break;
                    }
                } else if (try seq.nextElement(ally, Child) != null) {
                    // Expected end of sequence, but found an element.
                    return error.InvalidLength;
                }

                return fifo;
            } else if (is_buffer_dynamic) {
                var fifo = Value.init(ally);
                errdefer fifo.deinit();

                while (try seq.nextElement(ally, Child)) |elem| {
                    try fifo.writeItem(elem);
                }

                return fifo;
            } else {
                var list = std.ArrayList(Child).init(ally);
                errdefer list.deinit();

                while (try seq.nextElement(ally, Child)) |elem| {
                    try list.append(elem);
                }

                var fifo = Value.init(try list.toOwnedSlice());
                fifo.count = fifo.buf.len;

                return fifo;
            }
        }

        const is_buffer_dynamic = std.meta.FieldType(Value, .allocator) != void;
        const is_buffer_static = @typeInfo(std.meta.FieldType(Value, .buf)) == .array;

        const Child = std.meta.Child(std.meta.FieldType(Value, .buf));
    };
}
