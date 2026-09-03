const std = @import("std");
const src = @import("sources.zig");

const thor_version_string = "1.2.0";

/// Field defaults are the defaults of a plain `zig build`, so `.{}` describes a
/// real configuration. setupCi relies on this.
const BuildFlags = struct {
    //Rasterizer
    cpu_engine: bool = true,
    gl_engine: bool = false,
    wg_engine: bool = false,
    //Enable Partial Rendering in thorvg
    partial: bool = true,

    //loaders
    png_loader: bool = false,
    jpg_loader: bool = false,
    lottie_loader: bool = true,
    ttf_loader: bool = true,
    otf_loader: bool = false,
    webp_loader: bool = false,
    media_loader: bool = false,
    svg_loader: bool = true,

    gif_saver: bool = false,

    //Enable the multi-threading task scheduler in thorvg
    threads: bool = true,

    //Enable log message
    log: bool = false,

    //Enable File IO calls in thorvg
    file_io: bool = true,

    openmp: bool = false,
    // opengl_es: bool = false,
    lottie_expressions: bool = false,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const d: BuildFlags = .{};
    const flags: BuildFlags = .{
        .cpu_engine = b.option(bool, "cpu-engines", "Enable cpu rasterizer") orelse d.cpu_engine,
        .gl_engine = b.option(bool, "gl-engines", "Enable gl rasterizer") orelse d.gl_engine,
        .wg_engine = b.option(bool, "wg-engines", "Enable wg rasterizer") orelse d.wg_engine,

        .partial = b.option(bool, "partial", "Enable partial rendering") orelse d.partial,

        .png_loader = b.option(bool, "png_loader", "Enable png loader") orelse d.png_loader,
        .jpg_loader = b.option(bool, "jpg_loader", "Enable jpg loader") orelse d.jpg_loader,
        .lottie_loader = b.option(bool, "lottie_loader", "Enable lottie loader") orelse d.lottie_loader,
        .ttf_loader = b.option(bool, "ttf_loader", "Enable ttf loader") orelse d.ttf_loader,
        .otf_loader = b.option(bool, "otf_loader", "Enable otf loader") orelse d.otf_loader,
        .webp_loader = b.option(bool, "webp_loader", "Enable webp loader") orelse d.webp_loader,
        .media_loader = b.option(bool, "media_loader", "Enable media loader") orelse d.media_loader,
        .svg_loader = b.option(bool, "svg_loader", "Enable svg loader") orelse d.svg_loader,

        .gif_saver = b.option(bool, "gif_saver", "Enable gif saver") orelse d.gif_saver,

        // std::mutex needs -pthread on emscripten, which this does not pass.
        .threads = b.option(bool, "threads", "Enable multi-threading") orelse
            (d.threads and target.result.os.tag != .emscripten),
        .log = b.option(bool, "log", "Enable logging") orelse d.log,
        .file_io = b.option(bool, "file", "Enable file I/O") orelse d.file_io,
        .openmp = b.option(bool, "openmp", "Enable openmp") orelse d.openmp,
        .lottie_expressions = b.option(bool, "lottie_exp", "enable lottie expressions") orelse d.lottie_expressions,
    };

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Library linkage (default: static)",
    ) orelse .static;

    const lib, const run_test, const tc = buildThor(b, target, optimize, flags, linkage, true);
    b.installArtifact(lib);

    // Registered once. Inside buildThor, setupCi would overwrite it.
    tc.addModule("thorvg").linkLibrary(lib);

    run_test.stdio = .inherit;

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_test.step);
    setupCi(b, target);
}

const CpuFeatures = struct {
    neon: bool,
    avx2: bool,
};

pub fn buildThor(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    flags: BuildFlags,
    linkage: std.builtin.LinkMode,
    verbose_smoke: bool,
) struct { *std.Build.Step.Compile, *std.Build.Step.Run, *std.Build.Step.TranslateC } {
    const upstream = b.dependency("upstream", .{});
    const arm = target.result.cpu.arch.isArm();
    const aarch64 = target.result.cpu.arch.isAARCH64();
    const x86 = target.result.cpu.arch.isX86();

    const cpu_features: CpuFeatures = .{
        .neon = (aarch64 and std.Target.aarch64.featureSetHas(target.result.cpu.features, .neon)) or
            (arm and std.Target.arm.featureSetHas(target.result.cpu.features, .neon)),
        .avx2 = x86 and
            std.Target.x86.featureSetHas(target.result.cpu.features, .avx2),
    };

    const config = b.addConfigHeader(.{}, .{
        .THORVG_VERSION_STRING = thor_version_string,
        .THORVG_THREAD_SUPPORT = if (flags.threads) true else null,
        .THORVG_CPU_ENGINE_SUPPORT = if (flags.cpu_engine) true else null,
        .THORVG_GL_ENGINE_SUPPORT = if (flags.gl_engine) true else null,
        .THORVG_WG_ENGINE_SUPPORT = if (flags.wg_engine) true else null,
        .THORVG_PARTIAL_RENDER_SUPPORT = if (flags.partial) true else null,
        .THORVG_SVG_LOADER_SUPPORT = if (flags.svg_loader) true else null,
        .THORVG_PNG_LOADER_SUPPORT = if (flags.png_loader) true else null,
        .THORVG_JPG_LOADER_SUPPORT = if (flags.jpg_loader) true else null,
        .THORVG_LOTTIE_LOADER_SUPPORT = if (flags.lottie_loader) true else null,
        .THORVG_SFNT_LOADER_SUPPORT = if (flags.ttf_loader or flags.otf_loader) true else null,
        .THORVG_TTF_LOADER_SUPPORT = if (flags.ttf_loader) true else null,
        .THORVG_OTF_LOADER_SUPPORT = if (flags.otf_loader) true else null,
        .THORVG_WEBP_LOADER_SUPPORT = if (flags.webp_loader) true else null,
        .THORVG_MEDIA_LOADER_SUPPORT = if (flags.media_loader) true else null,
        .THORVG_GIF_SAVER_SUPPORT = if (flags.gif_saver) true else null,
        .THORVG_AVX_VECTOR_SUPPORT = if (cpu_features.avx2) true else null,
        .THORVG_NEON_VECTOR_SUPPORT = if (cpu_features.neon) true else null,
        .THORVG_CAPI_BINDING_SUPPORT = true,
        .THORVG_LOG_ENABLED = if (flags.log) true else null,
        .THORVG_FILE_IO_SUPPORT = if (flags.file_io) true else null,
        .THORVG_LOTTIE_EXPRESSIONS_SUPPORT = if (flags.lottie_expressions) true else null,
        .THORVG_OPENMP_SUPPORT = if (flags.openmp) true else null,
        .WIN32_LEAN_AND_MEAN = true,
    });

    // Mirrors upstream meson: cpp_std=c++14 plus the b_sanitize=none set and
    // gnu_symbol_visibility=hidden.
    const base_cflags = [_][]const u8{
        "-std=c++14",
        "-Wno-unknown-pragmas",
        "-Woverloaded-virtual",
        "-fno-exceptions",
        "-fno-rtti",
        "-fno-math-errno",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-fno-asynchronous-unwind-tables",
        "-fvisibility=hidden",
    };
    const cflags: []const []const u8 = if (flags.openmp)
        &(base_cflags ++ [_][]const u8{"-fopenmp"})
    else
        &base_cflags;

    const tc = b.addTranslateC(.{
        .root_source_file = upstream.path("src/bindings/capi/thorvg_capi.h"),
        .target = target,
        .optimize = optimize,
    });
    switch (linkage) {
        .static => tc.defineCMacro("TVG_STATIC", null),
        .dynamic => {
            tc.defineCMacro("TVG_EXPORT", null);
            tc.defineCMacro("TVG_BUILD", null);
        },
    }

    const mod = b.createModule(.{
        .root_source_file = tc.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    switch (linkage) {
        .static => mod.addCMacro("TVG_STATIC", "1"),
        .dynamic => {
            mod.addCMacro("TVG_EXPORT", "1");
            mod.addCMacro("TVG_BUILD", "1");
        },
    }
    if (target.result.os.tag == .windows) mod.addCMacro("NOMINMAX", "1");

    const lib = b.addLibrary(.{
        .name = "thorvg",
        .linkage = linkage,
        .root_module = mod,
    });

    switch (target.result.os.tag) {
        .windows, .emscripten => {},
        .linux => if (!target.result.abi.isAndroid()) mod.linkSystemLibrary("pthread", .{}),
        else => mod.linkSystemLibrary("pthread", .{}),
    }

    if (flags.cpu_engine and flags.openmp) mod.linkSystemLibrary("omp", .{});
    // Upstream: dependency('wgpu_native'). Emscripten gets WebGPU from the browser.
    if (flags.wg_engine and target.result.os.tag != .emscripten) {
        mod.linkSystemLibrary("wgpu_native", .{});
    }
    mod.link_libcpp = true;
    mod.link_libc = true;

    if (flags.media_loader and target.result.os.tag.isDarwin()) {
        if (b.sysroot) |sysroot| if (sysroot.len > 0) {
            mod.addSystemFrameworkPath(.{
                .cwd_relative = b.pathJoin(&.{ sysroot, "System/Library/Frameworks" }),
            });
        };
        mod.linkFramework("AVFoundation", .{});
        mod.linkFramework("CoreVideo", .{});
        mod.linkFramework("CoreMedia", .{});
        mod.linkFramework("Foundation", .{});
        mod.linkFramework("CoreFoundation", .{});
    }

    if (target.result.os.tag == .emscripten) {
        const sysroot = b.sysroot orelse "";
        if (sysroot.len == 0) @panic(
            \\wasm32-emscripten needs the emscripten sysroot:
            \\    zig build -Dtarget=wasm32-emscripten --sysroot <emsdk>/cache/sysroot
        );
        // -isystem, not addIncludePath: emscripten's libc has to be searched
        // after libc++'s own headers or <cstddef> rejects the ordering.
        mod.addSystemIncludePath(.{ .cwd_relative = b.pathJoin(&.{ sysroot, "include" }) });
    }

    lib.installHeader(upstream.path("inc/thorvg.h"), "thorvg/thorvg.h");
    lib.installHeadersDirectory(upstream.path("src/bindings/capi"), "thorvg", .{
        .include_extensions = &.{".h"},
    });
    if (flags.media_loader)
        lib.installHeader(upstream.path("src/loaders/media/thorvg_media.h"), "thorvg/thorvg_media.h");
    if (flags.lottie_loader)
        lib.installHeader(upstream.path("src/loaders/lottie/thorvg_lottie.h"), "thorvg/thorvg_lottie.h");

    mod.addConfigHeader(config);
    mod.addIncludePath(upstream.path("inc"));
    mod.addIncludePath(upstream.path("."));
    mod.addIncludePath(upstream.path("src"));
    mod.addIncludePath(upstream.path("src/common"));
    mod.addIncludePath(upstream.path("src/loaders"));
    if (flags.jpg_loader) {
        mod.addIncludePath(upstream.path("src/loaders/jpg"));
    }
    if (flags.png_loader) {
        mod.addIncludePath(upstream.path("src/loaders/png"));
    }
    if (flags.webp_loader) {
        mod.addIncludePath(upstream.path("src/loaders/webp"));
        mod.addIncludePath(upstream.path("src/loaders/webp/dec"));
        mod.addIncludePath(upstream.path("src/loaders/webp/dsp"));
        mod.addIncludePath(upstream.path("src/loaders/webp/utils"));
        mod.addIncludePath(upstream.path("src/loaders/webp/webp"));
    }
    if (flags.media_loader) {
        mod.addIncludePath(upstream.path("src/loaders/media"));
        if (target.result.os.tag.isDarwin()) {
            mod.addIncludePath(upstream.path("src/loaders/media/apple"));
        } else if (target.result.os.tag == .emscripten) {
            mod.addIncludePath(upstream.path("src/loaders/media/web"));
        }
    }
    if (flags.svg_loader)
        mod.addIncludePath(upstream.path("src/loaders/svg"));
    mod.addIncludePath(upstream.path("src/loaders/raw"));
    if (flags.ttf_loader or flags.otf_loader)
        mod.addIncludePath(upstream.path("src/loaders/sfnt"));
    if (flags.lottie_loader) {
        mod.addIncludePath(upstream.path("src/loaders/lottie"));
        if (flags.lottie_expressions) {
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/api"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/base"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects/typedarray"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/operations"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/include"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/jcontext"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/jmem"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/jrt"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/lit"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/parser"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/parser/js"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/parser/regexp"));
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/vm"));
            if (flags.threads)
                mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-port/common"));
        }
    }
    mod.addIncludePath(upstream.path("src/renderer"));
    if (flags.cpu_engine)
        mod.addIncludePath(upstream.path("src/renderer/cpu_engine"));
    if (flags.gl_engine or flags.wg_engine)
        mod.addIncludePath(upstream.path("src/renderer/gpu_engine"));
    if (flags.wg_engine)
        mod.addIncludePath(upstream.path("src/renderer/gpu_engine/wg"));
    if (flags.gl_engine)
        mod.addIncludePath(upstream.path("src/renderer/gpu_engine/gl"));
    mod.addIncludePath(upstream.path("src/savers"));
    if (flags.gif_saver)
        mod.addIncludePath(upstream.path("src/savers/gif"));
    mod.addIncludePath(upstream.path("src/bindings/capi"));

    addSources(mod, upstream, "src/common", &src.common, cflags);
    if (flags.jpg_loader) {
        addSources(mod, upstream, "src/loaders/jpg", &src.loaders_jpg, cflags);
    }
    if (flags.png_loader) {
        addSources(mod, upstream, "src/loaders/png", &src.loaders_png, cflags);
    }
    if (flags.webp_loader) {
        addSources(mod, upstream, "src/loaders/webp", &src.loaders_webp, cflags);
        addSources(mod, upstream, "src/loaders/webp/dec", &src.loaders_webp_dec, cflags);
        addSources(mod, upstream, "src/loaders/webp/dsp", &src.loaders_webp_dsp, cflags);
        addSources(mod, upstream, "src/loaders/webp/utils", &src.loaders_webp_utils, cflags);
    }
    if (flags.svg_loader)
        addSources(mod, upstream, "src/loaders/svg", &src.loaders_svg, cflags);
    if (flags.ttf_loader or flags.otf_loader)
        addSources(mod, upstream, "src/loaders/sfnt", &src.loaders_sfnt, cflags);
    if (flags.ttf_loader)
        addSources(mod, upstream, "src/loaders/sfnt", &src.loaders_sfnt_2, cflags);
    if (flags.otf_loader)
        addSources(mod, upstream, "src/loaders/sfnt", &src.loaders_sfnt_3, cflags);
    if (flags.media_loader) {
        addSources(mod, upstream, "src/loaders/media", &src.loaders_media, cflags);
        if (target.result.os.tag.isDarwin()) {
            addSources(mod, upstream, "src/loaders/media/apple", &src.loaders_media_apple, cflags);
        } else if (target.result.os.tag == .emscripten) {
            addSources(mod, upstream, "src/loaders/media/web", &src.loaders_media_web, cflags);
        } else {
            addSources(mod, upstream, "src/loaders/media", &src.loaders_media_2, cflags);
        }
    }
    if (flags.lottie_loader) {
        addSources(mod, upstream, "src/loaders/lottie", &src.loaders_lottie, cflags);
        if (flags.lottie_expressions) {
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/api", &src.loaders_lottie_jerryscript_jerry_core_api, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/ecma/base", &src.loaders_lottie_jerryscript_jerry_core_ecma_base, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects", &src.loaders_lottie_jerryscript_jerry_core_ecma_builtin_objects, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects/typedarray", &src.loaders_lottie_jerryscript_jerry_core_ecma_builtin_objects_typedarray, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/ecma/operations", &src.loaders_lottie_jerryscript_jerry_core_ecma_operations, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/jcontext", &src.loaders_lottie_jerryscript_jerry_core_jcontext, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/jmem", &src.loaders_lottie_jerryscript_jerry_core_jmem, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/jrt", &src.loaders_lottie_jerryscript_jerry_core_jrt, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/lit", &src.loaders_lottie_jerryscript_jerry_core_lit, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/parser/js", &src.loaders_lottie_jerryscript_jerry_core_parser_js, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/parser/regexp", &src.loaders_lottie_jerryscript_jerry_core_parser_regexp, cflags);
            addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-core/vm", &src.loaders_lottie_jerryscript_jerry_core_vm, cflags);
            if (flags.threads)
                addSources(mod, upstream, "src/loaders/lottie/jerryscript/jerry-port/common", &src.loaders_lottie_jerryscript_jerry_port_common, cflags);
        }
    }
    addSources(mod, upstream, "src/renderer", &src.renderer, cflags);
    if (flags.cpu_engine)
        addSources(mod, upstream, "src/renderer/cpu_engine", &src.renderer_cpu_engine, cflags);
    if (flags.gl_engine or flags.wg_engine)
        addSources(mod, upstream, "src/renderer/gpu_engine", &src.renderer_gpu_engine, cflags);
    if (flags.wg_engine)
        addSources(mod, upstream, "src/renderer/gpu_engine/wg", &src.renderer_gpu_engine_wg, cflags);
    if (flags.gl_engine)
        addSources(mod, upstream, "src/renderer/gpu_engine/gl", &src.renderer_gpu_engine_gl, cflags);
    if (flags.gif_saver)
        addSources(mod, upstream, "src/savers/gif", &src.savers_gif, cflags);
    addSources(mod, upstream, "src/loaders/raw", &src.loaders_raw, cflags);
    addSources(mod, upstream, "src/bindings/capi", &src.bindings_capi, cflags);
    const smoke_mod = b.createModule(.{
        .root_source_file = b.path("test/smoke.zig"),
        .target = target,
        .optimize = optimize,
    });
    smoke_mod.addImport("thorvg", tc.createModule());
    smoke_mod.linkLibrary(lib);

    const smoke_options = b.addOptions();
    smoke_options.addOption(bool, "verbose", verbose_smoke);
    smoke_mod.addOptions("smoke_options", smoke_options);

    const smoke = b.addExecutable(.{
        .name = "thorvg_smoke",
        .root_module = smoke_mod,
    });

    const run_test = b.addRunArtifact(smoke);
    run_test.expectExitCode(0);

    return .{ lib, run_test, tc };
}

pub fn setupCi(b: *std.Build, target: std.Build.ResolvedTarget) void {
    const ci = b.step("ci", "run ci");
    const configs: []const BuildFlags = &.{
        .{},
        .{
            .gl_engine = true,
            .png_loader = true,
            .jpg_loader = true,
            .otf_loader = true,
            .webp_loader = true,
            .gif_saver = true,
            .log = true,
            .lottie_expressions = true,
        },
        .{
            .cpu_engine = false,
            .partial = false,
            .lottie_loader = false,
            .ttf_loader = false,
            .svg_loader = false,
            .threads = false,
            .file_io = false,
        },
    };

    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu },
        .{ .cpu_arch = .arm, .os_tag = .linux, .abi = .musleabihf },
    };

    const linkages: []const std.builtin.LinkMode = &.{ .static, .dynamic };

    for (configs, 0..) |c, idx| {
        // SwCanvas needs the CPU engine, so the smoke test cannot run without it.
        const runnable = c.cpu_engine;

        for (linkages) |linkage| {
            const native_lib, const run_native_test, _ = buildThor(b, target, .Debug, c, linkage, false);
            ci.dependOn(&b.addInstallArtifact(native_lib, .{}).step);
            if (runnable) {
                run_native_test.setName(b.fmt("native-test-config #{} - {t}", .{ idx, linkage }));
                ci.dependOn(&run_native_test.step);
            }

            for (targets, 0..) |q, qidx| {
                const rt = b.resolveTargetQuery(q);
                const lib, const run_test, _ = buildThor(b, rt, .Debug, c, linkage, false);
                ci.dependOn(&b.addInstallArtifact(lib, .{}).step);
                if (!runnable) continue;
                run_test.setName(b.fmt("test-config #{} - {t} - target #{}", .{ idx, linkage, qidx }));
                run_test.failing_to_execute_foreign_is_an_error = false;
                run_test.skip_foreign_checks = true;
                ci.dependOn(&run_test.step);
            }
        }
    }
}

fn addSources(
    mod: *std.Build.Module,
    upstream: *std.Build.Dependency,
    root: []const u8,
    files: []const []const u8,
    cflags: []const []const u8,
) void {
    mod.addCSourceFiles(.{
        .root = upstream.path(root),
        .files = files,
        .flags = cflags,
    });
}
