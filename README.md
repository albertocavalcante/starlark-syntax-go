# starlark-syntax-go

Standalone Starlark syntax parsing for Go — automatically synced from upstream sources.

## Installation

```bash
go get github.com/albertocavalcante/starlark-syntax-go
```

## Packages

### `bzl` — Parser for Bazel's Starlark files

Parser for BUILD, .bzl, MODULE.bazel, and WORKSPACE files. Preserves comments attached to AST nodes (CST-like).

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
| **Origin** | [bazelbuild/buildtools](https://github.com/bazelbuild/buildtools) | [google/starlark-go](https://github.com/google/starlark-go) |
| **Target files** | BUILD, .bzl, MODULE.bazel, WORKSPACE | General .star files |
| **Comment handling** | Attached to AST nodes (CST-like) | Optional (`RetainComments` mode) |
| **Indentation** | Ignored (Bazel uses explicit delimiters) | Significant (Python-style blocks) |
| **Parser type** | Yacc-generated (LALR) | Hand-written recursive-descent (LL1) |

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
