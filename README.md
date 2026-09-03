# zig build for ThorVG

[ThorVG](https://github.com/thorvg/thorvg) built with the Zig build system.

## Use as a dependency

```sh
zig fetch --save git+https://github.com/<owner>/thorvg
```

```zig
const thorvg = b.dependency("thorvg", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("thorvg", thorvg.module("thorvg"));
```

```zig
const c = @import("thorvg");

if (c.tvg_engine_init(0) != c.TVG_RESULT_SUCCESS) return error.EngineInitFailed;
```

The module exposes the C API translated by `translate-c` and links the library,
so a single `addImport` is enough. Linkage defaults to static; pass
`.linkage = .dynamic` for a shared library.

The default build needs nothing installed. Zig supplies the compiler, libc and
libc++, so it cross-compiles out of the box:

```sh
zig build -Dtarget=x86_64-windows-gnu
zig build -Dtarget=aarch64-linux-musl
```

## Options

| Option | Default | |
|---|---|---|
| `-Dlinkage=static\|dynamic` | `static` | |
| `-Dcpu-engines` | `true` | software rasteriser |
| `-Dgl-engines` | `false` | |
| `-Dwg-engines` | `false` | needs wgpu-native |
| `-Dsvg_loader` | `true` | |
| `-Dlottie_loader` | `true` | |
| `-Dttf_loader` | `true` | |
| `-Dotf_loader` | `false` | |
| `-Dpng_loader` | `false` | bundled decoder |
| `-Djpg_loader` | `false` | bundled decoder |
| `-Dwebp_loader` | `false` | bundled decoder |
| `-Dmedia_loader` | `false` | needs the Apple SDK |
| `-Dgif_saver` | `false` | |
| `-Dlottie_exp` | `false` | Lottie expressions via JerryScript |
| `-Dpartial` | `true` | partial rendering |
| `-Dthreads` | `true` | off for emscripten, which has no `-pthread` here |
| `-Dfile` | `true` | file I/O |
| `-Dlog` | `false` | |
| `-Dopenmp` | `false` | needs libomp; upstream defaults this on, but `-lomp` cannot resolve when cross-compiling |

## Options that need something installed

Four features reach outside the toolchain. `--sysroot` and `--search-prefix`
are global flags, and dependency builds inherit them, so they work from a
consuming project too.

```sh
# libomp
zig build -Dopenmp=true

# Apple frameworks: AVFoundation and friends
zig build -Dmedia_loader=true --sysroot "$(xcrun --show-sdk-path)"

# wgpu-native: headers and libwgpu_native both under one prefix
zig build -Dwg-engines=true --search-prefix /path/to/wgpu-native

# emscripten libc headers
zig build -Dtarget=wasm32-emscripten --sysroot "$EMSDK/upstream/emscripten/cache/sysroot"
```

Known gaps: `-Dwg-engines` is host-only, since cross-compiling it needs a
`wgpu-native` built for the target, and it cannot be combined with emscripten,
which now requires the `emdawnwebgpu` port rather than a bundled `webgpu.h`.

## Development

`nix develop` provides Zig plus every optional dependency above, exporting
`SDKROOT`, `WGPU_PREFIX` and `EM_SYSROOT`. Note that `nix develop -c` does not
run a shell, so wrap anything using those variables:

```sh
nix develop -c bash -c 'zig build -Dwg-engines=true --search-prefix "$WGPU_PREFIX"'
```

```sh
zig build test   # rasterise a rectangle and print it
zig build ci     # 3 configs x 6 targets x 2 linkages
```

`sources.zig` holds the file lists; `build.zig` holds the logic.
