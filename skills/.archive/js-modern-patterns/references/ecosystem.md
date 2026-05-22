# JS/TS Ecosystem & Libraries

## Functional Programming
| Library | Description |
|---------|-------------|
| lodash | Utility library (deepClone, debounce, throttle) |
| ramda | Composable functional helpers (auto-curried) |
| rxjs | Reactive extensions (Observable streams) |
| immutable | Persistent data structures |

## Debugging & Profiling
| Library | Description |
|---------|-------------|
| debug | Namespaced debug logging |
| why-is-node-running | Find what keeps Node.js alive |
| 0x | Flamegraph profiling |
| clinic | Performance diagnostics |

## Testing
| Framework | Description |
|-----------|-------------|
| vitest | Fast Vite-native test runner (preferred) |
| jest | Zero-config test runner |
| ava | Parallel test runner |
| tap | TAP-producing framework |
| uvu | Ultra-fast test runner |

## Build Tools
| Tool | Description |
|------|-------------|
| vite | Fast dev server + HMR + optimized builds |
| esbuild | Extremely fast bundler (Go-based) |
| swc | Rust-based JS/TS compiler |
| turbopack | Incremental bundler |

## CLI & Terminal
chalk, yargs, meow, ora, inquirer, commander, zx

## Streams, Dates, Parsing, Compression
- **Streams:** highland, through2, pump
- **Dates:** date-fns (tree-shakeable), dayjs (2KB), luxon
- **Parsing:** zod, joi, fast-xml-parser, js-yaml, toml
- **Compression:** sharp, archiver, pako, lz4
