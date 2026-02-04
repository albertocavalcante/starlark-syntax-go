# starlark-syntax-go

[![CI](https://github.com/albertocavalcante/starlark-syntax-go/actions/workflows/ci.yml/badge.svg)](https://github.com/albertocavalcante/starlark-syntax-go/actions/workflows/ci.yml)
[![Sync](https://github.com/albertocavalcante/starlark-syntax-go/actions/workflows/sync.yml/badge.svg)](https://github.com/albertocavalcante/starlark-syntax-go/actions/workflows/sync.yml)
[![Go Reference](https://pkg.go.dev/badge/github.com/albertocavalcante/starlark-syntax-go.svg)](https://pkg.go.dev/github.com/albertocavalcante/starlark-syntax-go)
[![License](https://img.shields.io/github/license/albertocavalcante/starlark-syntax-go)](LICENSE)
[![Go Version](https://img.shields.io/github/go-mod/go-version/albertocavalcante/starlark-syntax-go)](go.mod)

Standalone Starlark **syntax parsing** for Go — automatically synced from upstream sources.

**Syntax only. No interpreter.** This package provides lexing, parsing, and AST manipulation — not code execution. If you need to evaluate Starlark code, use the full [google/starlark-go](https://github.com/google/starlark-go) package instead.

## Why This Package?

The official Starlark parsers live inside larger projects with heavy dependencies:

- **buildtools** includes formatters, linters, and rewriters you may not need
- **starlark-go** bundles the full interpreter, REPL, and standard library

This package extracts **just the syntax layer** for lightweight tooling. It stays current via automated [Copybara](https://github.com/google/copybara) syncs from upstream.

## Use Cases

- **Static analysis** — linters, security scanners, complexity checkers
- **Code transformation** — formatters, refactoring tools, migration scripts
- **Dependency extraction** — parse BUILD/MODULE.bazel to map the dependency graph
- **Editor tooling** — syntax highlighting, go-to-definition, hover info
- **Code generation** — programmatically build Starlark configs

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
