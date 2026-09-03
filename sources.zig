//! Source file lists, split out of build.zig to keep it readable.

pub const common = [_][]const u8{
    "tvgCompressor.cpp",
    "tvgMath.cpp",
    "tvgStr.cpp",
};

pub const loaders_jpg = [_][]const u8{
    "tvgJpgd.cpp",
    "tvgJpgLoader.cpp",
};

pub const loaders_png = [_][]const u8{
    "tvgLodePng.cpp",
    "tvgLodePngUtil.cpp",
    "tvgPngLoader.cpp",
};

pub const loaders_webp = [_][]const u8{
    "tvgWebpLoader.cpp",
};

pub const loaders_webp_dec = [_][]const u8{
    "alpha.cpp",
    "buffer.cpp",
    "frame.cpp",
    "io.cpp",
    "quant.cpp",
    "tree.cpp",
    "vp8.cpp",
    "vp8l.cpp",
    "webp.cpp",
};

pub const loaders_webp_dsp = [_][]const u8{
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
};

pub const loaders_webp_utils = [_][]const u8{
    "bit_reader.cpp",
    "color_cache.cpp",
    "huffman.cpp",
    "quant_levels_dec.cpp",
    "random.cpp",
    "rescaler.cpp",
};

pub const loaders_svg = [_][]const u8{
    "tvgSvgBuilder.cpp",
    "tvgSvgCssStyle.cpp",
    "tvgSvgLoader.cpp",
    "tvgSvgPath.cpp",
    "tvgSvgUtil.cpp",
    "tvgXmlParser.cpp",
};

pub const loaders_sfnt = [_][]const u8{
    "tvgSfntLoader.cpp",
    "tvgSfntReader.cpp",
};

pub const loaders_sfnt_2 = [_][]const u8{
    "tvgTtfReader.cpp",
};

pub const loaders_sfnt_3 = [_][]const u8{
    "tvgOtfReader.cpp",
};

pub const loaders_media = [_][]const u8{
    "tvgVideo.cpp",
};

pub const loaders_media_apple = [_][]const u8{
    "tvgAvfMediaLoader.mm",
};

pub const loaders_media_web = [_][]const u8{
    "tvgWebMediaLoader.cpp",
};

pub const loaders_media_2 = [_][]const u8{
    "tvgMediaLoader.cpp",
};

pub const loaders_lottie = [_][]const u8{
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
};

pub const loaders_lottie_jerryscript_jerry_core_api = [_][]const u8{
    "jerryscript.cpp",
};

pub const loaders_lottie_jerryscript_jerry_core_ecma_base = [_][]const u8{
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
};

pub const loaders_lottie_jerryscript_jerry_core_ecma_builtin_objects = [_][]const u8{
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
};

pub const loaders_lottie_jerryscript_jerry_core_ecma_builtin_objects_typedarray = [_][]const u8{
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
};

pub const loaders_lottie_jerryscript_jerry_core_ecma_operations = [_][]const u8{
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
};

pub const loaders_lottie_jerryscript_jerry_core_jcontext = [_][]const u8{
    "jcontext.cpp",
};

pub const loaders_lottie_jerryscript_jerry_core_jmem = [_][]const u8{
    "jmem-allocator.cpp",
    "jmem-heap.cpp",
    "jmem-poolman.cpp",
};

pub const loaders_lottie_jerryscript_jerry_core_jrt = [_][]const u8{
    "jrt-fatals.cpp",
    "jrt-logging.cpp",
};

pub const loaders_lottie_jerryscript_jerry_core_lit = [_][]const u8{
    "lit-char-helpers.cpp",
    "lit-magic-strings.cpp",
    "lit-strings.cpp",
};

pub const loaders_lottie_jerryscript_jerry_core_parser_js = [_][]const u8{
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
};

pub const loaders_lottie_jerryscript_jerry_core_parser_regexp = [_][]const u8{
    "re-bytecode.cpp",
    "re-compiler.cpp",
    "re-parser.cpp",
};

pub const loaders_lottie_jerryscript_jerry_core_vm = [_][]const u8{
    "opcodes-ecma-arithmetics.cpp",
    "opcodes-ecma-bitwise.cpp",
    "opcodes-ecma-relational-equality.cpp",
    "opcodes.cpp",
    "vm-stack.cpp",
    "vm-utils.cpp",
    "vm.cpp",
};

pub const loaders_lottie_jerryscript_jerry_port_common = [_][]const u8{
    "jerry-port-context.cpp",
};

pub const renderer = [_][]const u8{
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
};

pub const renderer_cpu_engine = [_][]const u8{
    "tvgSwBlendOp.cpp",
    "tvgSwFill.cpp",
    "tvgSwImage.cpp",
    "tvgSwMemPool.cpp",
    "tvgSwPostEffect.cpp",
    "tvgSwRaster.cpp",
    "tvgSwRenderer.cpp",
    "tvgSwRle.cpp",
    "tvgSwShape.cpp",
    "tvgSwStroke.cpp",
    "tvgSwUtil.cpp",
};

pub const renderer_gpu_engine = [_][]const u8{
    "tvgGpuCommon.cpp",
};

pub const renderer_gpu_engine_wg = [_][]const u8{
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
};

pub const renderer_gpu_engine_gl = [_][]const u8{
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
};

pub const savers_gif = [_][]const u8{
    "tvgGifEncoder.cpp",
    "tvgGifSaver.cpp",
};

pub const loaders_raw = [_][]const u8{
    "tvgRawLoader.cpp",
};

pub const bindings_capi = [_][]const u8{
    "tvgCapi.cpp",
};
