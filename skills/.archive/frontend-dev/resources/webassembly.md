# WebAssembly (WASM) & WebGPU

Run high-performance code in the browser at near-native speed.

## WebAssembly Basics

### What is WASM?

Binary instruction format for a stack-based virtual machine. Runs in all modern browsers, Node.js, and edge runtimes.

### Languages that compile to WASM

| Language | Tool | Use Case |
|---------|------|---------|
| Rust | `wasm-pack` | Best WASM support |
| C/C++ | Emscripten | Existing C/C++ code |
| Go | TinyGo | Embedded, small binaries |
| C# | Blazor | Web apps |

## Rust → WASM (Recommended)

### Setup

```bash
cargo install wasm-pack
wasm-pack build --target web
```

### Rust Code

```rust
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn fibonacci(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

#[wasm_bindgen]
pub struct Point {
    x: f64,
    y: f64,
}

#[wasm_bindgen]
impl Point {
    #[wasm_bindgen(constructor)]
    pub fn new(x: f64, y: f64) -> Point {
        Point { x, y }
    }

    pub fn distance(&self, other: &Point) -> f64 {
        ((self.x - other.x).powi(2) + (self.y - other.y).powi(2)).sqrt()
    }
}
```

### JavaScript Interop

```javascript
import init, { fibonacci, Point } from './pkg/my_wasm.js'

await init() // Load and compile WASM

// Call exported function
const result = fibonacci(10)  // 55

// Use exported class
const p1 = new Point(0, 0)
const p2 = new Point(3, 4)
console.log(p1.distance(p2))  // 5
```

## Emscripten (C/C++ → WASM)

```bash
emcc math_ops.c -o math_ops.js -s WASM=1
```

```c
// math_ops.c
#include <emscripten.h>

EMSCRIPTEN_KEEPALIVE
int add(int a, int b) {
    return a + b;
}
```

```javascript
const { add } = require('./math_ops.js')
console.log(add(2, 3))  // 5
```

## WebGL / WebGPU Integration

### WASM + WebGL (Rust)

```rust
// Rendering loop
#[wasm_bindgen]
impl Point {
    pub fn render(&self, canvas_id: &str) {
        let document = web_sys::window().unwrap();
        let canvas = document.get_element_by_id(canvas_id).unwrap();
        let ctx = canvas
            .dyn_into::<web_sys::HtmlCanvasElement>()
            .unwrap()
            .get_context("2d")
            .unwrap()
            .unwrap()
            .dyn_into::<web_sys::CanvasRenderingContext2d>()
            .unwrap();

        ctx.fill_rect(self.x, self.y, 10.0, 10.0);
    }
}
```

### WebGPU (Native GPU Access)

```javascript
// Check support
const adapter = await navigator.gpu.requestAdapter()
const device = await adapter.requestDevice()

// Compute shader example
const computeShader = `
  @group(0) @binding(0) var<storage, read_write> data: array<f32>;

  @compute @workgroup_size(64)
  fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    data[id.x] = data[id.x] * 2.0;
  }
`
```

## Performance Use Cases

| Use Case | Why WASM |
|----------|---------|
| Image/video processing | CPU-intensive pixel ops |
| Game physics | Near-native math performance |
| Encryption | Constant-time operations |
| Data parsing | Binary formats (Protocol Buffers) |
| Signal processing | DSP, FFT |

## Memory Model

```javascript
// Access WASM linear memory directly
const memory = instance.exports.memory
const buffer = new Float32Array(memory.buffer)

// Read from WASM memory
const view = new DataView(memory.buffer)
const value = view.getFloat32(0, true)  // little-endian
```

## SharedArrayBuffer (Multi-threaded WASM)

```javascript
// Requires secure context + COOP/COEP headers
const sharedBuffer = new SharedArrayBuffer(1024)
const worker = new Worker('wasm_worker.js')

// Worker receives the shared buffer
worker.postMessage({ buffer: sharedBuffer }, [sharedBuffer])
```

## Resources

- [awesome-wasm](https://github.com/idematos/awesome-webassembly)
- [webassembly.org](https://webassembly.org)
- [awesome-webgl](https://github.com/sjfricke/awesome-webgl)