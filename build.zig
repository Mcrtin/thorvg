const std = @import("std");

const thor_version_string = "1.2.0";

const BuildFlags = struct {
    //Rasterizer
    cpu_engine: bool = false,
    gl_engine: bool = false,
    wg_engine: bool = false,
    //Enable Partial Rendering in thorvg
    partial: bool = false,

    //loaders
    png_loader: bool = false,
    jpg_loader: bool = false,
    lottie_loader: bool = false,
    ttf_loader: bool = false,
    otf_loader: bool = false,
    webp_loader: bool = false,
    media_loader: bool = false,
    svg_loader: bool = false,

    gif_saver: bool = false,

    //Enable the multi-threading task scheduler in thorvg
    threads: bool = false,

    //Enable building Unit Tests
    tests: bool = false,

    //Enable log message
    log: bool = false,

    //Force to use static linking modules in thorvg
    static: bool = false,

    //Enable File IO calls in thorvg
    file_io: bool = false,

    openmp: bool = false,
    // opengl_es: bool = false,
    lottie_expressions: bool = false,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const flags: BuildFlags = .{
        .cpu_engine = b.option(bool, "cpu-engines", "Enable cpu rasterizer") orelse true,
        .gl_engine = b.option(bool, "gl-engines", "Enable gl rasterizer") orelse false,
        .wg_engine = b.option(bool, "wg-engines", "Enable wg rasterizer") orelse false,

        .partial = b.option(bool, "partial", "Enable partial rendering") orelse true,

        .png_loader = b.option(bool, "png_loader", "Enable png loader") orelse false,
        .jpg_loader = b.option(bool, "jpg_loader", "Enable jpg loader") orelse false,
        .lottie_loader = b.option(bool, "lottie_loader", "Enable lottie loader") orelse true,
        .ttf_loader = b.option(bool, "ttf_loader", "Enable ttf loader") orelse true,
        .otf_loader = b.option(bool, "otf_loader", "Enable otf loader") orelse false,
        .webp_loader = b.option(bool, "webp_loader", "Enable webp loader") orelse false,
        .media_loader = b.option(bool, "media_loader", "Enable media loader") orelse false,
        .svg_loader = b.option(bool, "svg_loader", "Enable svg loader") orelse true,

        .gif_saver = b.option(bool, "gif_saver", "Enable gif saver") orelse false,

        .threads = b.option(bool, "threads", "Enable multi-threading") orelse true,
        .tests = b.option(bool, "tests", "Enable tests") orelse false,
        .log = b.option(bool, "log", "Enable logging") orelse false,
        .static = b.option(bool, "static", "Force static linkage") orelse false,
        .file_io = b.option(bool, "file", "Enable file I/O") orelse true,
        .openmp = b.option(bool, "openmp", "Enable openmp") orelse true,
        .lottie_expressions = b.option(bool, "lottie_exp", "enable lottie expressions") orelse false,
    };

    const lib, const dynlib, const run_test = buildThor(b, target, optimize, flags);
    b.installArtifact(lib);
    b.installArtifact(dynlib);
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
) struct { *std.Build.Step.Compile, *std.Build.Step.Compile, *std.Build.Step.Run } {
    const upstream = b.dependency("upstream", .{});
    const arm = target.result.cpu.arch.isArm();
    const aarch64 = target.result.cpu.arch.isAARCH64();
    const x86 = target.result.cpu.arch.isX86();

    const cpu_features: CpuFeatures = .{
        .neon = (aarch64 or arm) and
            std.Target.aarch64.featureSetHas(target.result.cpu.features, .neon),
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

    const cflags: []const []const u8 = &.{}; //++ (if (is_shared) .{ "-DTVG_EXPORT", "-DTVG_BUILD" } else .{"-DTVG_STATIC"}) ++ (if (is_windows) .{'-DNOMINMAX'} else .{}) ++ .{}; //TODO: is msvc

    // const options: []const []const u8 = &.{};

    const tc = b.addTranslateC(.{
        .root_source_file = upstream.path("src/bindings/capi/thorvg_capi.h"),
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("thorvg", .{
        .root_source_file = tc.getOutput(),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "libthorvg",
        .linkage = .static,
        .root_module = mod,
    });

    const dynlib = b.addLibrary(.{
        .name = "libthorvg",
        .linkage = .dynamic,
        .root_module = mod,
    });

    switch (target.result.os.tag) {
        .windows, .emscripten => {},
        .linux => if (!target.result.abi.isAndroid()) mod.linkSystemLibrary("pthread", .{}),
        else => mod.linkSystemLibrary("pthread", .{}),
    }

    if (flags.cpu_engine and flags.openmp) mod.linkSystemLibrary("omp", .{});
    if (flags.wg_engine and target.result.os.tag != .emscripten) mod.linkSystemLibrary("omp", .{});
    mod.link_libcpp = true;
    mod.link_libc = true;

    if (flags.media_loader and target.result.os.tag.isDarwin()) {
        mod.linkFramework("AVFoundation", .{});
        mod.linkFramework("CoreVideo", .{});
        mod.linkFramework("CoreMedia", .{});
        mod.linkFramework("Foundation", .{});
        mod.linkFramework("CoreFoundation", .{});
    }

    lib.installHeadersDirectory(upstream.path("src/bindings/capi"), "thorvg", .{});
    if (flags.media_loader) lib.installHeadersDirectory(upstream.path("src/loaders/media/thorvg_media.h"), "thorvg", .{});
    if (flags.lottie_loader) lib.installHeadersDirectory(upstream.path("src/loaders/lottie/thorvg_lottie.h"), "thorvg", .{});

    mod.addConfigHeader(config);
    mod.addIncludePath(upstream.path("inc"));
    mod.addIncludePath(upstream.path("."));
    mod.addIncludePath(upstream.path("src"));
    mod.addIncludePath(upstream.path("src/common"));
    mod.addIncludePath(upstream.path("src/loaders"));
    if (flags.jpg_loader) {
        // mod.addIncludePath(upstream.path("src/loaders/external_jpg"));
        mod.addIncludePath(upstream.path("src/loaders/jpg"));
    }
    if (flags.png_loader) {
        // mod.addIncludePath(upstream.path("src/loaders/external_png"));
        mod.addIncludePath(upstream.path("src/loaders/png"));
    }
    if (flags.webp_loader) {
        // mod.addIncludePath(upstream.path("src/loaders/external_webp"));
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
            mod.addIncludePath(upstream.path("src/loaders/lottie/jerryscript/jerry-core/base/ecma"));
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
    mod.addIncludePath(upstream.path("src/renderer/gpu_engine"));
    if (flags.wg_engine)
        mod.addIncludePath(upstream.path("src/renderer/gpu_engine/wg"));
    if (flags.gl_engine)
        mod.addIncludePath(upstream.path("src/renderer/gpu_engine/gl"));
    mod.addIncludePath(upstream.path("src/savers"));
    if (flags.gif_saver)
        mod.addIncludePath(upstream.path("src/savers/gif"));
    mod.addIncludePath(upstream.path("src/bindings/capi"));

    mod.addCSourceFiles(.{
        .root = upstream.path("src/common"),
        .files = &.{
            "tvgArray.h",
            "tvgCommon.h",
            "tvgColor.h",
            "tvgCompressor.h",
            "tvgInlist.h",
            "tvgLock.h",
            "tvgMap.h",
            "tvgMath.h",
            "tvgStr.h",
            "tvgCompressor.cpp",
            "tvgMath.cpp",
            "tvgStr.cpp",
        },
        .flags = cflags,
    });
    if (flags.jpg_loader) {
        // mod.addCSourceFiles(.{
        //     .root = upstream.path("src/loaders/external_jpg"),
        //     .files = &.{
        //         "tvgJpgLoader.h",
        //         "tvgJpgLoader.cpp",
        //     },
        //     .flags = cflags,
        // });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/jpg"),
            .files = &.{
                "tvgJpgd.h",
                "tvgJpgLoader.h",
                "tvgJpgd.cpp",
                "tvgJpgLoader.cpp",
            },
            .flags = cflags,
        });
    }
    if (flags.png_loader) {
        // mod.addCSourceFiles(.{
        //     .root = upstream.path("src/loaders/external_png"),
        //     .files = &.{
        //         "tvgPngLoader.h",
        //         "tvgPngLoader.cpp",
        //     },
        //     .flags = cflags,
        // });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/png"),
            .files = &.{
                "tvgLodePng.h",
                "tvgPngLoader.h",
                "tvgLodePng.cpp",
                "tvgLodePngUtil.cpp",
                "tvgPngLoader.cpp",
            },
            .flags = cflags,
        });
    }
    if (flags.webp_loader) {
        // mod.addCSourceFiles(.{
        //     .root = upstream.path("src/loaders/external_webp"),
        //     .files = &.{
        //         "tvgWebpLoader.h",
        //         "tvgWebpLoader.cpp",
        //     },
        //     .flags = cflags,
        // });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/webp"),
            .files = &.{
                "tvgWebpLoader.h",
                "tvgWebpLoader.cpp",
            },
            .flags = cflags,
        });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/webp/dec"),
            .files = &.{
                "alphai.h",
                "common.h",
                "decode_vp8.h",
                "vp8i.h",
                "vp8li.h",
                "webpi.h",
                "alpha.cpp",
                "buffer.cpp",
                "frame.cpp",
                "io.cpp",
                "quant.cpp",
                "tree.cpp",
                "vp8.cpp",
                "vp8l.cpp",
                "webp.cpp",
            },
            .flags = cflags,
        });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/webp/dsp"),
            .files = &.{
                "yuv.h",
                "dsp.h",
                "lossless.h",
                "alpha_processing.cpp",
                "argb.cpp",
                "cpu.cpp",
                "dec.cpp",
                "dec_clip_tables.cpp",
                "filters.cpp",
                "lossless.cpp",
                "rescaler.cpp",
                "upsampling.cpp",
                "yuv.cpp",
            },
            .flags = cflags,
        });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/webp/utils"),
            .files = &.{
                "bit_reader.h",
                "bit_reader_inl.h",
                "color_cache.h",
                "endian_inl.h",
                "huffman.h",
                "quant_levels_dec.h",
                "random.h",
                "rescaler.h",
                "utils.h",
                "bit_reader.cpp",
                "color_cache.cpp",
                "huffman.cpp",
                "quant_levels_dec.cpp",
                "random.cpp",
                "rescaler.cpp",
            },
            .flags = cflags,
        });
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/webp/webp"),
            .files = &.{
                "decode.h",
                "format_constants.h",
                "types.h",
            },
            .flags = cflags,
        });
    }
    if (flags.svg_loader)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/svg"),
            .files = &.{
                "tvgSvgBuilder.h",
                "tvgSvgCommon.h",
                "tvgSvgCssStyle.h",
                "tvgSvgLoader.h",
                "tvgSvgPath.h",
                "tvgSvgUtil.h",
                "tvgXmlParser.h",
                "tvgSvgBuilder.cpp",
                "tvgSvgCssStyle.cpp",
                "tvgSvgLoader.cpp",
                "tvgSvgPath.cpp",
                "tvgSvgUtil.cpp",
                "tvgXmlParser.cpp",
            },
            .flags = cflags,
        });
    if (flags.ttf_loader or flags.otf_loader)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/sfnt"),
            .files = &.{
                "tvgSfntLoader.h",
                "tvgSfntReader.h",
                "tvgSfntLoader.cpp",
                "tvgSfntReader.cpp",
            },
            .flags = cflags,
        });
    if (flags.ttf_loader)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/sfnt"),
            .files = &.{
                "tvgTtfReader.h",
                "tvgTtfReader.cpp",
            },
            .flags = cflags,
        });
    if (flags.otf_loader)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/sfnt"),
            .files = &.{
                "tvgOtfReader.h",
                "tvgOtfReader.cpp",
            },
            .flags = cflags,
        });
    if (flags.media_loader) {
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/media"),
            .files = &.{
                "tvgMediaLoader.h",
                "tvgVideo.cpp",
            },
            .flags = cflags,
        });
        if (target.result.os.tag.isDarwin()) {
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/media/apple"),
                .files = &.{
                    "tvgAvfMediaLoader.h",
                    "tvgAvfMediaLoader.mm",
                },
                .flags = cflags,
            });
        } else if (target.result.os.tag == .emscripten) {
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/media/web"),
                .files = &.{
                    "tvgWebMediaLoader.h",
                    "tvgWebMediaLoader.cpp",
                },
                .flags = cflags,
            });
        } else {
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/media"),
                .files = &.{
                    "tvgMediaLoader.cpp",
                },
                .flags = cflags,
            });
        }
    }
    if (flags.lottie_loader) {
        mod.addCSourceFiles(.{
            .root = upstream.path("src/loaders/lottie"),
            .files = &.{
                "tvgLottieBuilder.h",
                "tvgLottieCommon.h",
                "tvgLottieExpressions.h",
                "tvgLottieInterpolator.h",
                "tvgLottieLoader.h",
                "tvgLottieModel.h",
                "tvgLottieModifier.h",
                "tvgLottieParser.h",
                "tvgLottieParserHandler.h",
                "tvgLottieProperty.h",
                "tvgLottieRenderPooler.h",
                "tvgLottieTween.h",
                "tvgLottieAnimation.cpp",
                "tvgLottieBuilder.cpp",
                "tvgLottieExpressions.cpp",
                "tvgLottieInterpolator.cpp",
                "tvgLottieLoader.cpp",
                "tvgLottieModel.cpp",
                "tvgLottieModifier.cpp",
                "tvgLottieParserHandler.cpp",
                "tvgLottieParser.cpp",
                "tvgLottieProperty.cpp",
            },
            .flags = cflags,
        });
        if (flags.lottie_expressions) {
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/api"),
                .files = &.{
                    "jerryscript.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/base/ecma"),
                .files = &.{
                    "ecma-alloc.h",
                    "ecma-error-messages.inc.h",
                    "ecma-errors.h",
                    "ecma-extended-info.h",
                    "ecma-gc.h",
                    "ecma-globals.h",
                    "ecma-helpers-number.h",
                    "ecma-helpers.h",
                    "ecma-init-finalize.h",
                    "ecma-lcache.h",
                    "ecma-literal-storage.h",
                    "ecma-module.h",
                    "ecma-property-hashmap.h",
                    "ecma-alloc.cpp",
                    "ecma-errors.cpp",
                    "ecma-extended-info.cpp",
                    "ecma-gc.cpp",
                    "ecma-helpers-collection.cpp",
                    "ecma-helpers-conversion.cpp",
                    "ecma-helpers-errol.cpp",
                    "ecma-helpers-external-pointers.cpp",
                    "ecma-helpers-number.cpp",
                    "ecma-helpers-string.cpp",
                    "ecma-helpers-value.cpp",
                    "ecma-helpers.cpp",
                    "ecma-init-finalize.cpp",
                    "ecma-lcache.cpp",
                    "ecma-literal-storage.cpp",
                    "ecma-module.cpp",
                    "ecma-property-hashmap.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/base"),
                .files = &.{
                    "ecma-alloc.h",
                    "ecma-error-messages.inc.h",
                    "ecma-errors.h",
                    "ecma-extended-info.h",
                    "ecma-gc.h",
                    "ecma-globals.h",
                    "ecma-helpers-number.h",
                    "ecma-helpers.h",
                    "ecma-init-finalize.h",
                    "ecma-lcache.h",
                    "ecma-literal-storage.h",
                    "ecma-module.h",
                    "ecma-property-hashmap.h",
                    "ecma-alloc.cpp",
                    "ecma-errors.cpp",
                    "ecma-extended-info.cpp",
                    "ecma-gc.cpp",
                    "ecma-helpers-collection.cpp",
                    "ecma-helpers-conversion.cpp",
                    "ecma-helpers-errol.cpp",
                    "ecma-helpers-external-pointers.cpp",
                    "ecma-helpers-number.cpp",
                    "ecma-helpers-string.cpp",
                    "ecma-helpers-value.cpp",
                    "ecma-helpers.cpp",
                    "ecma-init-finalize.cpp",
                    "ecma-lcache.cpp",
                    "ecma-literal-storage.cpp",
                    "ecma-module.cpp",
                    "ecma-property-hashmap.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects"),
                .files = &.{
                    "ecma-builtin-aggregateerror-prototype.inc.h",
                    "ecma-builtin-aggregateerror.inc.h",
                    "ecma-builtin-array-iterator-prototype.inc.h",
                    "ecma-builtin-array-prototype-unscopables.inc.h",
                    "ecma-builtin-array-prototype.inc.h",
                    "ecma-builtin-array.inc.h",
                    "ecma-builtin-arraybuffer-prototype.inc.h",
                    "ecma-builtin-arraybuffer.inc.h",
                    "ecma-builtin-async-from-sync-iterator-prototype.inc.h",
                    "ecma-builtin-async-function-prototype.inc.h",
                    "ecma-builtin-async-function.inc.h",
                    "ecma-builtin-async-generator-function.inc.h",
                    "ecma-builtin-async-generator-prototype.inc.h",
                    "ecma-builtin-async-generator.inc.h",
                    "ecma-builtin-async-iterator-prototype.inc.h",
                    "ecma-builtin-atomics.inc.h",
                    "ecma-builtin-bigint-prototype.inc.h",
                    "ecma-builtin-bigint.inc.h",
                    "ecma-builtin-boolean-prototype.inc.h",
                    "ecma-builtin-boolean.inc.h",
                    "ecma-builtin-dataview-prototype.inc.h",
                    "ecma-builtin-dataview.inc.h",
                    "ecma-builtin-date-prototype.inc.h",
                    "ecma-builtin-date.inc.h",
                    "ecma-builtin-error-prototype.inc.h",
                    "ecma-builtin-error.inc.h",
                    "ecma-builtin-evalerror-prototype.inc.h",
                    "ecma-builtin-evalerror.inc.h",
                    "ecma-builtin-function-prototype.h",
                    "ecma-builtin-function-prototype.inc.h",
                    "ecma-builtin-function.inc.h",
                    "ecma-builtin-generator-function.inc.h",
                    "ecma-builtin-generator-prototype.inc.h",
                    "ecma-builtin-generator.inc.h",
                    "ecma-builtin-global.inc.h",
                    "ecma-builtin-handlers.h",
                    "ecma-builtin-handlers.inc.h",
                    "ecma-builtin-helpers-macro-defines.inc.h",
                    "ecma-builtin-helpers-macro-undefs.inc.h",
                    "ecma-builtin-helpers.h",
                    "ecma-builtin-internal-routines-template.inc.h",
                    "ecma-builtin-intrinsic.inc.h",
                    "ecma-builtin-iterator-prototype.inc.h",
                    "ecma-builtin-map-iterator-prototype.inc.h",
                    "ecma-builtin-map-prototype.inc.h",
                    "ecma-builtin-map.inc.h",
                    "ecma-builtin-math.inc.h",
                    "ecma-builtin-number-prototype.inc.h",
                    "ecma-builtin-number.inc.h",
                    "ecma-builtin-object-prototype.inc.h",
                    "ecma-builtin-object.h",
                    "ecma-builtin-object.inc.h",
                    "ecma-builtin-promise-prototype.inc.h",
                    "ecma-builtin-promise.inc.h",
                    "ecma-builtin-proxy.inc.h",
                    "ecma-builtin-rangeerror-prototype.inc.h",
                    "ecma-builtin-rangeerror.inc.h",
                    "ecma-builtin-referenceerror-prototype.inc.h",
                    "ecma-builtin-referenceerror.inc.h",
                    "ecma-builtin-reflect.inc.h",
                    "ecma-builtin-regexp-prototype.inc.h",
                    "ecma-builtin-regexp-string-iterator-prototype.inc.h",
                    "ecma-builtin-regexp.inc.h",
                    "ecma-builtin-set-iterator-prototype.inc.h",
                    "ecma-builtin-set-prototype.inc.h",
                    "ecma-builtin-set.inc.h",
                    "ecma-builtin-shared-arraybuffer-prototype.inc.h",
                    "ecma-builtin-shared-arraybuffer.inc.h",
                    "ecma-builtin-string-iterator-prototype.inc.h",
                    "ecma-builtin-string-prototype.inc.h",
                    "ecma-builtin-string.inc.h",
                    "ecma-builtin-symbol-prototype.inc.h",
                    "ecma-builtin-symbol.inc.h",
                    "ecma-builtin-syntaxerror-prototype.inc.h",
                    "ecma-builtin-syntaxerror.inc.h",
                    "ecma-builtin-type-error-thrower.inc.h",
                    "ecma-builtin-typeerror-prototype.inc.h",
                    "ecma-builtin-typeerror.inc.h",
                    "ecma-builtin-urierror-prototype.inc.h",
                    "ecma-builtin-urierror.inc.h",
                    "ecma-builtin-weakmap-prototype.inc.h",
                    "ecma-builtin-weakmap.inc.h",
                    "ecma-builtin-weakref-prototype.inc.h",
                    "ecma-builtin-weakref.inc.h",
                    "ecma-builtin-weakset-prototype.inc.h",
                    "ecma-builtin-weakset.inc.h",
                    "ecma-builtins-internal.h",
                    "ecma-builtins.h",
                    "ecma-builtins.inc.h",
                    "ecma-builtin-aggregateerror-prototype.cpp",
                    "ecma-builtin-aggregateerror.cpp",
                    "ecma-builtin-array-iterator-prototype.cpp",
                    "ecma-builtin-array-prototype-unscopables.cpp",
                    "ecma-builtin-array-prototype.cpp",
                    "ecma-builtin-array.cpp",
                    "ecma-builtin-arraybuffer-prototype.cpp",
                    "ecma-builtin-arraybuffer.cpp",
                    "ecma-builtin-async-from-sync-iterator-prototype.cpp",
                    "ecma-builtin-async-function-prototype.cpp",
                    "ecma-builtin-async-function.cpp",
                    "ecma-builtin-async-generator-function.cpp",
                    "ecma-builtin-async-generator-prototype.cpp",
                    "ecma-builtin-async-generator.cpp",
                    "ecma-builtin-async-iterator-prototype.cpp",
                    "ecma-builtin-atomics.cpp",
                    "ecma-builtin-bigint-prototype.cpp",
                    "ecma-builtin-bigint.cpp",
                    "ecma-builtin-boolean-prototype.cpp",
                    "ecma-builtin-boolean.cpp",
                    "ecma-builtin-dataview-prototype.cpp",
                    "ecma-builtin-dataview.cpp",
                    "ecma-builtin-date-prototype.cpp",
                    "ecma-builtin-date.cpp",
                    "ecma-builtin-error-prototype.cpp",
                    "ecma-builtin-error.cpp",
                    "ecma-builtin-evalerror-prototype.cpp",
                    "ecma-builtin-evalerror.cpp",
                    "ecma-builtin-function-prototype.cpp",
                    "ecma-builtin-function.cpp",
                    "ecma-builtin-generator-function.cpp",
                    "ecma-builtin-generator-prototype.cpp",
                    "ecma-builtin-generator.cpp",
                    "ecma-builtin-global.cpp",
                    "ecma-builtin-handlers.cpp",
                    "ecma-builtin-helpers-date.cpp",
                    "ecma-builtin-helpers-error.cpp",
                    "ecma-builtin-helpers-sort.cpp",
                    "ecma-builtin-helpers.cpp",
                    "ecma-builtin-intrinsic.cpp",
                    "ecma-builtin-iterator-prototype.cpp",
                    "ecma-builtin-map-iterator-prototype.cpp",
                    "ecma-builtin-map-prototype.cpp",
                    "ecma-builtin-map.cpp",
                    "ecma-builtin-math.cpp",
                    "ecma-builtin-number-prototype.cpp",
                    "ecma-builtin-number.cpp",
                    "ecma-builtin-object-prototype.cpp",
                    "ecma-builtin-object.cpp",
                    "ecma-builtin-promise-prototype.cpp",
                    "ecma-builtin-promise.cpp",
                    "ecma-builtin-proxy.cpp",
                    "ecma-builtin-rangeerror-prototype.cpp",
                    "ecma-builtin-rangeerror.cpp",
                    "ecma-builtin-referenceerror-prototype.cpp",
                    "ecma-builtin-referenceerror.cpp",
                    "ecma-builtin-reflect.cpp",
                    "ecma-builtin-regexp-prototype.cpp",
                    "ecma-builtin-regexp-string-iterator-prototype.cpp",
                    "ecma-builtin-regexp.cpp",
                    "ecma-builtin-set-iterator-prototype.cpp",
                    "ecma-builtin-set-prototype.cpp",
                    "ecma-builtin-set.cpp",
                    "ecma-builtin-shared-arraybuffer-prototype.cpp",
                    "ecma-builtin-shared-arraybuffer.cpp",
                    "ecma-builtin-string-iterator-prototype.cpp",
                    "ecma-builtin-string-prototype.cpp",
                    "ecma-builtin-string.cpp",
                    "ecma-builtin-symbol-prototype.cpp",
                    "ecma-builtin-symbol.cpp",
                    "ecma-builtin-syntaxerror-prototype.cpp",
                    "ecma-builtin-syntaxerror.cpp",
                    "ecma-builtin-type-error-thrower.cpp",
                    "ecma-builtin-typeerror-prototype.cpp",
                    "ecma-builtin-typeerror.cpp",
                    "ecma-builtin-urierror-prototype.cpp",
                    "ecma-builtin-urierror.cpp",
                    "ecma-builtin-weakmap-prototype.cpp",
                    "ecma-builtin-weakmap.cpp",
                    "ecma-builtin-weakref-prototype.cpp",
                    "ecma-builtin-weakref.cpp",
                    "ecma-builtin-weakset-prototype.cpp",
                    "ecma-builtin-weakset.cpp",
                    "ecma-builtins.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects/typedarray"),
                .files = &.{
                    "ecma-builtin-bigint64array-prototype.inc.h",
                    "ecma-builtin-bigint64array.inc.h",
                    "ecma-builtin-biguint64array-prototype.inc.h",
                    "ecma-builtin-biguint64array.inc.h",
                    "ecma-builtin-float32array-prototype.inc.h",
                    "ecma-builtin-float32array.inc.h",
                    "ecma-builtin-int16array-prototype.inc.h",
                    "ecma-builtin-int16array.inc.h",
                    "ecma-builtin-int32array-prototype.inc.h",
                    "ecma-builtin-int32array.inc.h",
                    "ecma-builtin-int8array-prototype.inc.h",
                    "ecma-builtin-int8array.inc.h",
                    "ecma-builtin-typedarray-helpers.h",
                    "ecma-builtin-typedarray-prototype-template.inc.h",
                    "ecma-builtin-typedarray-prototype.inc.h",
                    "ecma-builtin-typedarray-template.inc.h",
                    "ecma-builtin-typedarray.inc.h",
                    "ecma-builtin-uint16array-prototype.inc.h",
                    "ecma-builtin-uint16array.inc.h",
                    "ecma-builtin-uint32array-prototype.inc.h",
                    "ecma-builtin-uint32array.inc.h",
                    "ecma-builtin-uint8array-prototype.inc.h",
                    "ecma-builtin-uint8array.inc.h",
                    "ecma-builtin-uint8clampedarray-prototype.inc.h",
                    "ecma-builtin-uint8clampedarray.inc.h",
                    "ecma-builtin-bigint64array-prototype.cpp",
                    "ecma-builtin-bigint64array.cpp",
                    "ecma-builtin-biguint64array-prototype.cpp",
                    "ecma-builtin-biguint64array.cpp",
                    "ecma-builtin-float32array-prototype.cpp",
                    "ecma-builtin-float32array.cpp",
                    "ecma-builtin-int16array-prototype.cpp",
                    "ecma-builtin-int16array.cpp",
                    "ecma-builtin-int32array-prototype.cpp",
                    "ecma-builtin-int32array.cpp",
                    "ecma-builtin-int8array-prototype.cpp",
                    "ecma-builtin-int8array.cpp",
                    "ecma-builtin-typedarray-helpers.cpp",
                    "ecma-builtin-typedarray-prototype.cpp",
                    "ecma-builtin-typedarray.cpp",
                    "ecma-builtin-uint16array-prototype.cpp",
                    "ecma-builtin-uint16array.cpp",
                    "ecma-builtin-uint32array-prototype.cpp",
                    "ecma-builtin-uint32array.cpp",
                    "ecma-builtin-uint8array-prototype.cpp",
                    "ecma-builtin-uint8array.cpp",
                    "ecma-builtin-uint8clampedarray-prototype.cpp",
                    "ecma-builtin-uint8clampedarray.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/ecma/builtin-objects/operations"),
                .files = &.{
                    "ecma-arguments-object.h",
                    "ecma-array-object.h",
                    "ecma-arraybuffer-object.h",
                    "ecma-async-generator-object.h",
                    "ecma-atomics-object.h",
                    "ecma-big-uint.h",
                    "ecma-bigint-object.h",
                    "ecma-bigint.h",
                    "ecma-boolean-object.h",
                    "ecma-comparison.h",
                    "ecma-container-object.h",
                    "ecma-conversion.h",
                    "ecma-dataview-object.h",
                    "ecma-eval.h",
                    "ecma-exceptions.h",
                    "ecma-function-object.h",
                    "ecma-iterator-object.h",
                    "ecma-jobqueue.h",
                    "ecma-lex-env.h",
                    "ecma-number-object.h",
                    "ecma-objects-general.h",
                    "ecma-objects.h",
                    "ecma-promise-object.h",
                    "ecma-proxy-object.h",
                    "ecma-reference.h",
                    "ecma-regexp-object.h",
                    "ecma-shared-arraybuffer-object.h",
                    "ecma-string-object.h",
                    "ecma-symbol-object.h",
                    "ecma-typedarray-object.h",
                    "ecma-arguments-object.cpp",
                    "ecma-array-object.cpp",
                    "ecma-arraybuffer-object.cpp",
                    "ecma-async-generator-object.cpp",
                    "ecma-atomics-object.cpp",
                    "ecma-big-uint.cpp",
                    "ecma-bigint-object.cpp",
                    "ecma-bigint.cpp",
                    "ecma-boolean-object.cpp",
                    "ecma-comparison.cpp",
                    "ecma-container-object.cpp",
                    "ecma-conversion.cpp",
                    "ecma-dataview-object.cpp",
                    "ecma-eval.cpp",
                    "ecma-exceptions.cpp",
                    "ecma-function-object.cpp",
                    "ecma-get-put-value.cpp",
                    "ecma-iterator-object.cpp",
                    "ecma-jobqueue.cpp",
                    "ecma-lex-env.cpp",
                    "ecma-number-object.cpp",
                    "ecma-objects-general.cpp",
                    "ecma-objects.cpp",
                    "ecma-promise-object.cpp",
                    "ecma-proxy-object.cpp",
                    "ecma-reference.cpp",
                    "ecma-regexp-object.cpp",
                    "ecma-shared-arraybuffer-object.cpp",
                    "ecma-string-object.cpp",
                    "ecma-symbol-object.cpp",
                    "ecma-typedarray-object.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/include"),
                .files = &.{
                    "jerry-config.h",
                    "jerryscript-compiler.h",
                    "jerryscript-core.h",
                    "jerryscript-port.h",
                    "jerryscript-types.h",
                    "jerryscript.h",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/jcontext"),
                .files = &.{
                    "jcontext.h",
                    "jcontext.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/jmem"),
                .files = &.{
                    "jmem-allocator-internal.h",
                    "jmem.h",
                    "jmem-allocator.cpp",
                    "jmem-heap.cpp",
                    "jmem-poolman.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/jrt"),
                .files = &.{
                    "jrt-bit-fields.h",
                    "jrt-libc-includes.h",
                    "jrt-types.h",
                    "jrt.h",
                    "jrt-fatals.cpp",
                    "jrt-logging.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/lit"),
                .files = &.{
                    "lit-char-helpers.h",
                    "lit-globals.h",
                    "lit-magic-strings.h",
                    "lit-magic-strings.inc.h",
                    "lit-strings.h",
                    "lit-unicode-conversions-sup.inc.h",
                    "lit-unicode-conversions.inc.h",
                    "lit-unicode-folding.inc.h",
                    "lit-unicode-ranges-sup.inc.h",
                    "lit-unicode-ranges.inc.h",
                    "lit-char-helpers.cpp",
                    "lit-magic-strings.cpp",
                    "lit-strings.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/parser/js"),
                .files = &.{
                    "byte-code.h",
                    "common.h",
                    "js-lexer.h",
                    "js-parser-limits.h",
                    "js-parser.h",
                    "js-scanner.h",
                    "js-parser-internal.h",
                    "js-parser-tagged-template-literal.h",
                    "js-scanner-internal.h",
                    "parser-errors.h",
                    "parser-error-messages.inc.h",
                    "byte-code.cpp",
                    "common.cpp",
                    "js-lexer.cpp",
                    "js-parser.cpp",
                    "js-parser-expr.cpp",
                    "js-parser-mem.cpp",
                    "js-parser-module.cpp",
                    "js-parser-statm.cpp",
                    "js-parser-tagged-template-literal.cpp",
                    "js-parser-util.cpp",
                    "js-scanner.cpp",
                    "js-scanner-ops.cpp",
                    "js-scanner-util.cpp",
                    "parser-errors.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/parser/regexp"),
                .files = &.{
                    "re-bytecode.h",
                    "re-compiler-context.h",
                    "re-compiler.h",
                    "re-parser.h",
                    "re-token.h",
                    "re-bytecode.cpp",
                    "re-compiler.cpp",
                    "re-parser.cpp",
                },
                .flags = cflags,
            });
            mod.addCSourceFiles(.{
                .root = upstream.path("src/loaders/lottie/jerryscript/jerry-core/vm"),
                .files = &.{
                    "opcodes.h",
                    "vm-defines.h",
                    "vm-stack.h",
                    "vm.h",
                    "opcodes-ecma-arithmetics.cpp",
                    "opcodes-ecma-bitwise.cpp",
                    "opcodes-ecma-relational-equality.cpp",
                    "opcodes.cpp",
                    "vm-stack.cpp",
                    "vm-utils.cpp",
                    "vm.cpp",
                },
                .flags = cflags,
            });
            if (flags.threads)
                mod.addCSourceFiles(.{
                    .root = upstream.path("src/loaders/lottie/jerryscript/jerry-port/common"),
                    .files = &.{
                        "jerry-port-context.cpp",
                    },
                    .flags = cflags,
                });
        }
    }
    mod.addCSourceFiles(.{
        .root = upstream.path("src/renderer"),
        .files = &.{
            "tvgAnimation.h",
            "tvgCanvas.h",
            "tvgFill.h",
            "tvgLoader.h",
            "tvgLoaderMgr.h",
            "tvgPicture.h",
            "tvgRender.h",
            "tvgAccessor.h",
            "tvgSaveModule.h",
            "tvgScene.h",
            "tvgShape.h",
            "tvgTaskScheduler.h",
            "tvgText.h",
            "tvgAccessor.cpp",
            "tvgAnimation.cpp",
            "tvgCanvas.cpp",
            "tvgFill.cpp",
            "tvgInitializer.cpp",
            "tvgLoaderMgr.cpp",
            "tvgPaint.cpp",
            "tvgPicture.cpp",
            "tvgRender.cpp",
            "tvgSaver.cpp",
            "tvgScene.cpp",
            "tvgShape.cpp",
            "tvgTaskScheduler.cpp",
            "tvgText.cpp",
        },
        .flags = cflags,
    });
    if (flags.cpu_engine)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/renderer/cpu_engine"),
            .files = &.{
                "tvgSwCommon.h",
                "tvgSwRasterC.h",
                "tvgSwRasterAvx.h",
                "tvgSwRasterNeon.h",
                "tvgSwRasterTexmap.h",
                "tvgSwBlendOp.cpp",
                "tvgSwFill.cpp",
                "tvgSwImage.cpp",
                "tvgSwMemPool.cpp",
                "tvgSwPostEffect.cpp",
                "tvgSwRenderer.h",
                "tvgSwRaster.cpp",
                "tvgSwRenderer.cpp",
                "tvgSwRle.cpp",
                "tvgSwShape.cpp",
                "tvgSwStroke.cpp",
                "tvgSwUtil.cpp",
            },
            .flags = cflags,
        });
    mod.addCSourceFiles(.{
        .root = upstream.path("src/renderer/gpu_engine"),
        .files = &.{
            "tvgGpuCommon.h",
            "tvgGpuCommon.cpp",
        },
        .flags = cflags,
    });
    if (flags.wg_engine)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/renderer/gpu_engine/wg"),
            .files = &.{
                "tvgWgBindGroups.h",
                "tvgWgCommon.h",
                "tvgWgCompositor.h",
                "tvgWgGeometry.h",
                "tvgWgPipelines.h",
                "tvgWgRenderData.h",
                "tvgWgRenderer.h",
                "tvgWgRenderTarget.h",
                "tvgWgRenderTask.h",
                "tvgWgShaderSrc.h",
                "tvgWgShaderTypes.h",
                "tvgWgSolidBatch.h",
                "tvgWgStencilBatch.h",
                "tvgWgTextureMgr.h",
                "tvgWgTessellator.h",
                "tvgWgBindGroups.cpp",
                "tvgWgCommon.cpp",
                "tvgWgCompositor.cpp",
                "tvgWgGeometry.cpp",
                "tvgWgPipelines.cpp",
                "tvgWgRenderData.cpp",
                "tvgWgRenderer.cpp",
                "tvgWgRenderTarget.cpp",
                "tvgWgRenderTask.cpp",
                "tvgWgShaderSrc.cpp",
                "tvgWgShaderTypes.cpp",
                "tvgWgSolidBatch.cpp",
                "tvgWgStencilBatch.cpp",
                "tvgWgTextureMgr.cpp",
                "tvgWgTessellator.cpp",
            },
            .flags = cflags,
        });
    if (flags.gl_engine)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/renderer/gpu_engine/gl"),
            .files = &.{
                "tvgGl.h",
                "tvgGlCommon.h",
                "tvgGlEffect.h",
                "tvgGlGpuBuffer.h",
                "tvgGlTextureMgr.h",
                "tvgGlProgram.h",
                "tvgGlRenderer.h",
                "tvgGlRenderPass.h",
                "tvgGlRenderTarget.h",
                "tvgGlRenderTask.h",
                "tvgGlShader.h",
                "tvgGlShaderSrc.h",
                "tvgGlSolidBatch.h",
                "tvgGlStateCache.h",
                "tvgGlStencilCoverBatch.h",
                "tvgGl.cpp",
                "tvgGlEffect.cpp",
                "tvgGlGeometry.cpp",
                "tvgGlGpuBuffer.cpp",
                "tvgGlTextureMgr.cpp",
                "tvgGlProgram.cpp",
                "tvgGlRenderer.cpp",
                "tvgGlSolidBatch.cpp",
                "tvgGlRenderPass.cpp",
                "tvgGlRenderTarget.cpp",
                "tvgGlRenderTask.cpp",
                "tvgGlShader.cpp",
                "tvgGlShaderSrc.cpp",
                "tvgGlStateCache.cpp",
                "tvgGlStencilCoverBatch.cpp",
                "tvgGlTessellator.cpp",
                "tvgGlTessellator.h",
            },
            .flags = cflags,
        });
    if (flags.gif_saver)
        mod.addCSourceFiles(.{
            .root = upstream.path("src/savers/gif"),
            .files = &.{
                "tvgGifEncoder.h",
                "tvgGifSaver.h",
                "tvgGifEncoder.cpp",
                "tvgGifSaver.cpp",
            },
            .flags = cflags,
        });
    mod.addCSourceFiles(.{
        .root = upstream.path("src/bindings/capi"),
        .files = &.{
            "tvgCapi.cpp",
        },
        .flags = cflags,
    });
    b.installArtifact(lib);

    const test_opus_api = b.addExecutable(.{
        .name = "test_opus_api",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    test_opus_api.root_module.linkLibrary(lib);
    test_opus_api.root_module.addCSourceFile(.{
        .file = upstream.path("tests/test_opus_api.c"),
        .flags = &.{
            "-fno-sanitize=undefined",
        },
    });
    test_opus_api.root_module.addIncludePath(upstream.path("celt"));

    const run_test = b.addRunArtifact(test_opus_api);
    run_test.has_side_effects = false;

    return .{ lib, dynlib, run_test };
}

pub fn setupCi(b: *std.Build, target: std.Build.ResolvedTarget) void {
    const ci = b.step("ci", "run ci");
    const configs: []const BuildFlags = &.{
        .{},
    };

    const targets: []const std.Target.Query = &.{
        .{ .cpu_arch = .aarch64, .os_tag = .macos },
        .{ .cpu_arch = .x86_64, .os_tag = .macos },
        .{ .cpu_arch = .aarch64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
        .{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu },
    };

    for (configs, 0..) |c, idx| {
        const native_lib, const native_dynlib, const run_native_test = buildThor(b, target, .Debug, c);
        ci.dependOn(&b.addInstallArtifact(native_lib, .{}).step);
        ci.dependOn(&b.addInstallArtifact(native_dynlib, .{}).step);
        run_native_test.setName(b.fmt("native-test-config #{} - {} ", .{ idx, c }));
        ci.dependOn(&run_native_test.step);

        for (targets, 0..) |q, qidx| {
            const rt = b.resolveTargetQuery(q);
            const lib, const dynlib, const run_test = buildThor(b, rt, .Debug, c);
            ci.dependOn(&b.addInstallArtifact(lib, .{}).step);
            ci.dependOn(&b.addInstallArtifact(dynlib, .{}).step);
            run_test.setName(b.fmt("test-config #{} - target # {} ", .{ idx, qidx }));
            run_test.failing_to_execute_foreign_is_an_error = false;
            run_test.skip_foreign_checks = true;
            ci.dependOn(&run_test.step);
        }
    }
}
