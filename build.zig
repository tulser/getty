const std = @import("std");

const package_name = "getty";
const src_dir = "src/";
const package_path = src_dir ++ package_name ++ ".zig";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const protest_options = .{ .target = target, .optimize = optimize };
    const protest_module = b.dependency("protest", protest_options).module("protest");

    const common_module = b.createModule(.{ .root_source_file = b.path(src_dir ++ "common/root.zig") });

    const imports = [_]std.Build.Module.Import{
        .{
            .name = "protest",
            .module = protest_module,
        },
        // internal import required for tests
        .{
            .name = "common",
            .module = common_module,
        },
    };

    _ = b.addModule(package_name, .{
        .root_source_file = b.path(package_path),
        .imports = &imports,
    });

    // Tests
    {
        const test_all_step = b.step("test", "Run tests");
        // For LSP checking.
        const check_step = b.step("check", "LSP compile check step");
        check_step.dependOn(test_all_step);

        // Filtered testing.
        if (b.args) |args| {
            std.debug.assert(args.len != 0); // b.args would be null if no arguments were given.

            const tests_filtered = b.addTest(.{
                .name = "filtered test",
                .filters = args,
                .root_module = b.createModule(.{
                    .root_source_file = b.path(package_path),
                    .target = target,
                    .optimize = optimize,
                }),
            });

            inline for (imports) |import| {
                tests_filtered.root_module.addImport(import.name, import.module);
            }
            test_all_step.dependOn(&b.addRunArtifact(tests_filtered).step);

            return;
        }

        const test_ser_step = b.step("test-ser", "Run serialization tests");
        const test_deser_step = b.step("test-deser", "Run deserialization tests");

        // Serialization tests.
        const test_ser = b.addTest(.{
            .name = "serialization test",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/ser/ser.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        inline for (imports) |import| {
            test_ser.root_module.addImport(import.name, import.module);
        }
        test_ser_step.dependOn(&b.addRunArtifact(test_ser).step);
        test_all_step.dependOn(test_ser_step);

        // Deserialization tests.
        const test_deser = b.addTest(.{
            .name = "deserialization test",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/de/de.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        inline for (imports) |import| {
            test_deser.root_module.addImport(import.name, import.module);
        }
        test_deser_step.dependOn(&b.addRunArtifact(test_deser).step);
        test_all_step.dependOn(test_deser_step);
    }

    // Documentation
    {
        const docs_step = b.step("docs", "Build the project documentation");

        const doc_obj = b.addObject(.{
            .name = "docs",
            .root_module = b.createModule(.{
                .root_source_file = b.path(package_path),
                .target = target,
                .optimize = optimize,
            }),
        });
        inline for (imports) |import| {
            doc_obj.root_module.addImport(import.name, import.module);
        }

        const install_docs = b.addInstallDirectory(.{
            .source_dir = doc_obj.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs/getty",
        });
        docs_step.dependOn(&install_docs.step);
    }
}
