# Facet

GPU-accelerated 2D compositor in [Salt](https://github.com/bneb/salt). Bezier
flattening to Metal compute — Z3-verified bounds on sequential pixel writes,
runtime-checked on random-access. Matches C performance at 457 fps. macOS only
(requires Metal).

## Architecture

| Layer | Lines | What |
|-------|------|------|
| Raster | ~600 | Adaptive de Casteljau flattening, signed-area coverage, scanline fill |
| Window | ~640 | macOS framebuffer bridge (ObjC FFI), pixel buffer presentation |
| Compositor | ~700 | Scene graph with layers, affine transforms, damage rectangles |
| UI | ~900 | Declarative widget tree, layout engine, text rendering |
| GPU | ~450 | Metal compute pipeline via ObjC FFI |

## Quick Start

```bash
cargo install saltc --git https://github.com/bneb/salt
git clone https://github.com/bneb/facet.git
cd facet
make demo-tiger
```

Renders the Facet Tiger (~30 paths, 160 cubic Beziers) at 457 fps on Apple M4.

## Performance

Measured on Apple M4 Pro, 512x512 canvas, Tiger benchmark (30 paths).

| Benchmark | Salt | C (-O3) | Ratio |
|-----------|------|---------|-------|
| Tiger render | 2,186 us | 2,214 us | 0.99x |

C reference is included at `raster/facet_raster.c` — same algorithm, `clang -O3`.

## Safety

Sequential pixel writes (e.g. `clear()`) are statically proven via `Slice<u8>`
with while-loop invariants — Z3 discharges every per-byte bound at compile time
with zero runtime overhead. Random-access `set_pixel(x, y)` carries a Z3-verified
`requires` contract that is runtime-checked (the 2D→1D mapping `y*stride + x*4`
is nonlinear and defers to a runtime bounds check).

```salt
// Statically proven — 0 deferred:
pub fn clear(&mut self, r: u8, g: u8, b: u8, a: u8) {
    let total = (self.stride as i64) * (self.height as i64);
    let pixels = Slice::<u8>::new(self.pixels, total);
    let mut off: i64 = 0;
    while off + 4 <= pixels.len() {
        invariant off >= 0;
        pixels.set(off, r);
        pixels.set(off + 1, g);
        pixels.set(off + 2, b);
        pixels.set(off + 3, a);
        off = off + 4;
    }
}

// Runtime-checked — 2D→1D nonlinear:
pub fn set_pixel(&mut self, x: i32, y: i32, ...)
    requires(x >= 0 && x < self.width && y >= 0 && y < self.height)
{ ... }
```

52 tests across raster, compositor, UI, and GPU layers.

## License

MIT

## Performance Benchmarks

See [Salt Benchmarks](https://github.com/bneb/salt-benchmarks) for Salt vs C/Rust across 36 algorithm problems.

## Built With

[Salt](https://github.com/bneb/salt) — a systems language with Z3-powered compile-time verification.
