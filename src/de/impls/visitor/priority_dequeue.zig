const std = @import("std");

const free = @import("../../free.zig").free;
const VisitorInterface = @import("../../interfaces/visitor.zig").Visitor;

pub fn Visitor(comptime PriorityDequeue: type) type {
    return struct {
        const Self = @This();

        pub usingnamespace VisitorInterface(
            Self,
            Value,
            .{ .visitSeq = visitSeq },
        );

        const Value = PriorityDequeue;

        fn visitSeq(_: Self, allocator: ?std.mem.Allocator, comptime Deserializer: type, seq: anytype) Deserializer.Error!Value {
            if (allocator == null) {
                return error.MissingAllocator;
            }

            const a = allocator.?;

            const T = std.meta.Child(std.meta.FieldType(Value, .items));
            const Context = std.meta.FieldType(Value, .context);

            if (@sizeOf(Context) != 0) {
                @compileError("non void context is not supported");
            }

            var deque = Value.init(a, undefined);
            errdefer free(a, Deserializer, deque);

            while (try seq.nextElement(a, T)) |elem| {
                try deque.add(elem);
            }

            return deque;
        }
    };
}
