//! Links the artifact and renders one rectangle through the C API.
//!
//! A static archive never reports undefined symbols on its own, so this
//! catches a missing translation unit that `zig build` would otherwise hide.

const std = @import("std");
const c = @import("thorvg");
const opts = @import("smoke_options");

const size = 64;
const inset = 8;

pub fn main() !void {
    if (c.tvg_engine_init(0) != c.TVG_RESULT_SUCCESS) return error.EngineInitFailed;

    var major: u32 = 0;
    var minor: u32 = 0;
    var micro: u32 = 0;
    var version: [*c]const u8 = null;
    if (c.tvg_engine_version(&major, &minor, &micro, &version) != c.TVG_RESULT_SUCCESS) {
        return error.VersionQueryFailed;
    }

    var buf: [size * size]u32 = @splat(0);
    const canvas = c.tvg_swcanvas_create(c.TVG_ENGINE_OPTION_DEFAULT) orelse
        return error.CanvasCreateFailed;
    if (c.tvg_swcanvas_set_target(canvas, &buf, size, size, size, c.TVG_COLORSPACE_ARGB8888) != c.TVG_RESULT_SUCCESS) {
        return error.SetTargetFailed;
    }

    const shape = c.tvg_shape_new() orelse return error.ShapeNewFailed;
    _ = c.tvg_shape_append_rect(shape, inset, inset, size - 2 * inset, size - 2 * inset, 0, 0, true);
    _ = c.tvg_shape_set_fill_color(shape, 255, 0, 0, 255);
    _ = c.tvg_canvas_add(canvas, shape);
    _ = c.tvg_canvas_draw(canvas, true);
    _ = c.tvg_canvas_sync(canvas);

    if (opts.verbose) report(&buf, major, minor, micro);

    // Opaque red centre, transparent corner. Proves the rasteriser ran instead
    // of leaving the buffer zeroed.
    if (buf[(size / 2) * size + size / 2] != 0xffff0000) return error.UnexpectedCenterPixel;
    if (buf[0] != 0x00000000) return error.UnexpectedCornerPixel;

    _ = c.tvg_canvas_destroy(canvas);
    _ = c.tvg_engine_term();
}

/// Dumps the render target. Rows are sampled in pairs so the square canvas
/// still looks square in a terminal.
fn report(buf: *const [size * size]u32, major: u32, minor: u32, micro: u32) void {
    std.debug.print("thorvg {d}.{d}.{d}\n", .{ major, minor, micro });

    var y: usize = 0;
    while (y < size) : (y += 2) {
        var line: [size]u8 = undefined;
        for (0..size) |x| line[x] = if (buf[y * size + x] >> 24 != 0) '#' else '.';
        std.debug.print("  {s}\n", .{line});
    }
}
