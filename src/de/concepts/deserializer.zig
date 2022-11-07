//! Compile-time type restraint for implementations of getty.Deserializer.

const std = @import("std");

const concept = "getty.Deserializer";

pub fn @"getty.Deserializer"(comptime T: type) void {
    comptime {
        if (!std.meta.trait.isContainer(T) or !std.meta.trait.hasField("context")(T)) {
            @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `context` declaration", .{concept}));
        }

        inline for (.{
            "Error",
            "dt",
            "user_dt",
            "deserializer_dt",
            "deserializeBool",
            "deserializeEnum",
            "deserializeFloat",
            "deserializeInt",
            "deserializeMap",
            "deserializeOptional",
            "deserializeSeq",
            "deserializeString",
            "deserializeStruct",
            "deserializeUnion",
            "deserializeVoid",
        }) |decl| {
            if (!@hasDecl(T, decl)) {
                @compileError(std.fmt.comptimePrint("concept `{s}` was not satisfied: missing `{s}` declaration", .{ concept, decl }));
            }
        }
    }
}
