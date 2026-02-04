# starlark-syntax-go

Standalone Starlark syntax parsing for Go — automatically synced from upstream sources.

## Installation

```bash
go get github.com/albertocavalcante/starlark-syntax-go
```

## Packages

### `bzl` — Bzl Dialect (Starlark + Bazel builtins)

Parser optimized for BUILD, .bzl, and MODULE.bazel files. Preserves comments as CST-like attached nodes.

```go
import "github.com/albertocavalcante/starlark-syntax-go/bzl"

content := []byte(`module(name = "example", version = "1.0.0")`)
file, err := bzl.Parse("MODULE.bazel", content)
```

**Source**: [bazelbuild/buildtools](https://github.com/bazelbuild/buildtools) (Apache 2.0)

### `starlark` — Pure Starlark

Official Google Starlark parser with full language support including indentation.

```go
import "github.com/albertocavalcante/starlark-syntax-go/starlark"

content := []byte(`def greet(name): return "Hello, " + name`)
file, err := starlark.Parse("example.star", content, 0)
```

**Source**: [google/starlark-go](https://github.com/google/starlark-go) (BSD-3-Clause)

## Why Two Parsers?

| Aspect | `bzl` | `starlark` |
|--------|-------|------------|
| **Semantics** | Bzl dialect (Starlark + Bazel builtins) | Pure Starlark |
| **Optimized for** | BUILD, .bzl, MODULE.bazel files | General .star files |
| **Comment handling** | CST-style (attached to nodes) | Optional retention |
| **Indentation** | Not needed (flat files) | Full support |
| **Parser type** | Yacc-generated | Recursive-descent |

## Versioning

Versions follow: `v0.YYYYMMDD.N`

See `VERSION.json` for exact upstream commit references.

## Acknowledgements

This package automatically syncs code from:

- **[bazelbuild/buildtools](https://github.com/bazelbuild/buildtools)** — Apache 2.0, Copyright The Bazel Authors
- **[google/starlark-go](https://github.com/google/starlark-go)** — BSD-3-Clause, Copyright The Go Authors

See `NOTICE` and individual `LICENSE` files for full attribution.

## License

Apache 2.0 — See [LICENSE](LICENSE)
