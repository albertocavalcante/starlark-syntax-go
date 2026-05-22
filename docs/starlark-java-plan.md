# starlark-java Extraction Plan

## Executive Summary

Extract the Starlark Java implementation from `bazelbuild/bazel` into a standalone repository. Unlike the Go version (syntax-only), this can include the **full interpreter** because the Bazel developers explicitly designed it to be independent.

**Key Finding:** The implementation lives in `net.starlark.java` (not `com.google.devtools.build`) with BUILD files containing explicit comments: _"Do not add Bazel or Google dependencies here!"_

**Naming Decision:** `starlark-java` (not `starlark-java-bazel`) — the code is clean enough to be pure Starlark.

## Source Analysis

### Location in Bazel Repository

```
bazel/src/main/java/net/starlark/java/
├── annot/      # 6 files  - Annotation framework (@StarlarkMethod, @StarlarkBuiltin)
├── cmd/        # 1 file   - Standalone REPL (Main.java)
├── eval/       # 50 files - Interpreter/evaluator
├── lib/json/   # 1 file   - JSON module (HAS BAZEL COUPLING - see below)
├── spelling/   # 1 file   - SpellChecker for error suggestions
└── syntax/     # 54 files - Lexer, parser, AST, resolver
```

**Total:** ~112 Java files, ~1.5 MB of code

### Dependency Analysis

| Module | Bazel Dependencies | External Dependencies |
|--------|-------------------|----------------------|
| `syntax` | NONE ✓ | Guava, JSR305, AutoValue |
| `eval` | NONE ✓ | Guava, JSR305, Flogger, AutoValue, Error Prone |
| `annot` | NONE ✓ | Guava, JSR305 |
| `spelling` | NONE ✓ | Guava |
| `cmd` | NONE ✓ | Guava |
| `lib/json` | **1 import** ⚠️ | Guava |

### The One Coupling Point

`lib/json/Json.java` line 22:
```java
import com.google.devtools.build.lib.packages.NativeInfo;
```

Used to serialize Bazel-specific objects to JSON. Only ~4 lines reference it out of ~800.

**Options:**
1. **Exclude lib/json/** — Simplest, users can add JSON support themselves
2. **Abstract it** — Create interface, move Bazel handling to adapter
3. **Remove the import** — Make it fail gracefully for unknown types

**Recommendation:** Option 1 for initial release, Option 2 as enhancement.

## Extraction Strategy

### What to Extract

```
starlark-java/
├── src/main/java/net/starlark/java/
│   ├── annot/           # Annotation framework
│   ├── eval/            # Full interpreter
│   ├── spelling/        # Error suggestions
│   └── syntax/          # Lexer, parser, AST
├── src/main/java/net/starlark/java/cmd/
│   └── Main.java        # Standalone REPL (optional)
├── pom.xml              # Maven build (converted from Bazel)
├── LICENSE              # Apache 2.0 (same as Bazel)
└── README.md
```

### What to Exclude

- `lib/json/` — Has Bazel coupling (can add later with abstraction)
- Test files — Initially exclude, add later if dependencies are clean
- Native profiler — Optional JNI code, not needed for core functionality

## Copybara Configuration

```python
core.workflow(
    name = "sync-starlark-java",

    origin = git.origin(
        url = "https://github.com/bazelbuild/bazel.git",
        ref = "master",
    ),

    destination = git.github_destination(
        url = "https://github.com/albertocavalcante/starlark-java.git",
        push = "main",
    ),

    origin_files = glob(
        include = [
            "src/main/java/net/starlark/java/annot/**/*.java",
            "src/main/java/net/starlark/java/eval/**/*.java",
            "src/main/java/net/starlark/java/spelling/**/*.java",
            "src/main/java/net/starlark/java/syntax/**/*.java",
            "src/main/java/net/starlark/java/cmd/Main.java",
            "LICENSE",
        ],
        exclude = [
            "**/*_test.java",
            "**/testing/**",
            "**/lib/json/**",  # Exclude due to Bazel coupling
        ],
    ),

    destination_files = glob(
        include = ["src/**", "LICENSE"],
        exclude = ["src/**/doc-files/**"],  # Preserve our docs
    ),

    mode = "ITERATIVE",
    authoring = authoring.pass_thru("Eukia[bot] <eukia[bot]@users.noreply.github.com>"),

    transformations = [
        # Flatten the deep Bazel source path
        core.move("src/main/java", "src/main/java"),
        core.move("LICENSE", "LICENSE-starlark"),

        metadata.expose_label("Co-authored-by"),
        metadata.expose_label("Signed-off-by"),
        metadata.add_header("Synced-From: bazelbuild/bazel/src/main/java/net/starlark/java"),
    ],
)
```

## Build System Conversion

### From Bazel to Maven

The Bazel BUILD files declare explicit dependencies that map cleanly to Maven:

```xml
<dependencies>
    <!-- Core dependencies -->
    <dependency>
        <groupId>com.google.guava</groupId>
        <artifactId>guava</artifactId>
        <version>33.0.0-jre</version>
    </dependency>
    <dependency>
        <groupId>com.google.code.findbugs</groupId>
        <artifactId>jsr305</artifactId>
        <version>3.0.2</version>
    </dependency>

    <!-- Annotation processing -->
    <dependency>
        <groupId>com.google.auto.value</groupId>
        <artifactId>auto-value-annotations</artifactId>
        <version>1.10.4</version>
    </dependency>
    <dependency>
        <groupId>com.google.auto.value</groupId>
        <artifactId>auto-value</artifactId>
        <version>1.10.4</version>
        <scope>provided</scope>
    </dependency>

    <!-- Logging (optional, can stub) -->
    <dependency>
        <groupId>com.google.flogger</groupId>
        <artifactId>flogger</artifactId>
        <version>0.8</version>
    </dependency>

    <!-- Error Prone annotations -->
    <dependency>
        <groupId>com.google.errorprone</groupId>
        <artifactId>error_prone_annotations</artifactId>
        <version>2.24.1</version>
    </dependency>
</dependencies>
```

### Alternative: Gradle

Could also use Gradle with Kotlin DSL for more modern tooling.

## Challenges & Mitigations

### Challenge 1: Build System Conversion

**Problem:** Bazel → Maven/Gradle conversion
**Mitigation:**
- Dependencies are explicit in BUILD files
- Can generate pom.xml programmatically
- Consider using `bazel-to-maven` tools

### Challenge 2: Flogger Dependency

**Problem:** Flogger (Google's logging) may not be desired by all users
**Mitigation:**
- Make it optional via SLF4J bridge
- Or stub it out with no-op logger

### Challenge 3: Sync Frequency

**Problem:** Bazel repo is huge, syncing is slower
**Mitigation:**
- Copybara's ITERATIVE mode only syncs changes
- Use sparse checkout if needed
- Cache Copybara state

### Challenge 4: API Stability

**Problem:** Not a guaranteed stable API
**Mitigation:**
- Document this clearly in README
- Use semantic versioning to signal breaking changes
- Consider API compatibility layer

## Repository Structure

```
starlark-java/
├── .copybara/
│   └── copy.bara.sky
├── .github/
│   └── workflows/
│       ├── ci.yml           # Build + test on PRs
│       └── sync.yml         # Weekly Copybara sync
├── src/
│   └── main/
│       └── java/
│           └── net/
│               └── starlark/
│                   └── java/
│                       ├── annot/
│                       ├── eval/
│                       ├── spelling/
│                       └── syntax/
├── docs/
│   └── examples/
├── pom.xml
├── LICENSE                  # Apache 2.0
├── LICENSE-starlark         # Original from Bazel
├── NOTICE
├── README.md
└── VERSION.json
```

## Implementation Phases

### Phase 1: Repository Setup
- [ ] Create `starlark-java` GitHub repository
- [ ] Set up basic Maven/Gradle build structure
- [ ] Create LICENSE, NOTICE, README

### Phase 2: Initial Sync
- [ ] Write Copybara configuration
- [ ] Test locally with `--dry-run`
- [ ] Run initial sync with `--init-history`
- [ ] Verify build compiles

### Phase 3: Build Configuration
- [ ] Complete pom.xml with all dependencies
- [ ] Set up annotation processing for AutoValue
- [ ] Verify all modules compile
- [ ] Add basic smoke tests

### Phase 4: CI/CD
- [ ] GitHub Actions for CI (build, test)
- [ ] Copybara sync workflow
- [ ] Maven Central publishing workflow
- [ ] Dependabot configuration

### Phase 5: Documentation
- [ ] README with usage examples
- [ ] API documentation
- [ ] Migration guide from Bazel's copy
- [ ] Contributing guidelines

### Phase 6: Publishing
- [ ] Publish to Maven Central
- [ ] Create GitHub releases
- [ ] Announce on relevant channels

## Usage Examples

### Syntax-Only (Parsing)

```java
import net.starlark.java.syntax.*;

String code = "def hello(name): return 'Hello, ' + name";
ParserInput input = ParserInput.fromString(code, "<example>");
StarlarkFile file = StarlarkFile.parse(input);

if (!file.ok()) {
    for (SyntaxError error : file.errors()) {
        System.err.println(error);
    }
} else {
    // Access AST
    for (Statement stmt : file.getStatements()) {
        System.out.println(stmt);
    }
}
```

### Full Interpretation

```java
import net.starlark.java.eval.*;
import net.starlark.java.syntax.*;

String code = """
    def factorial(n):
        if n <= 1:
            return 1
        return n * factorial(n - 1)

    result = factorial(5)
    """;

// Create execution context
Module module = Module.create();
try (Mutability mu = Mutability.create("example")) {
    StarlarkThread thread = StarlarkThread.createTransient(mu, StarlarkSemantics.DEFAULT);

    // Parse and execute
    ParserInput input = ParserInput.fromString(code, "<example>");
    ExecResult result = Starlark.execFile(input, FileOptions.DEFAULT, module, thread);

    // Get result
    Object value = module.getGlobal("result");
    System.out.println("factorial(5) = " + value);  // 120
}
```

## Comparison with starlark-syntax-go

| Aspect | starlark-syntax-go | starlark-java |
|--------|-------------------|---------------|
| **Scope** | Syntax only (2 parsers) | Full interpreter |
| **Source** | buildtools + starlark-go | bazel |
| **Coupling** | None | 1 file (excluded) |
| **Build** | Go modules | Maven/Gradle |
| **Size** | ~20 files | ~112 files |
| **Complexity** | Simple | Medium |

## Open Questions

1. **Maven vs Gradle?** — Maven is more common in enterprise, Gradle is more modern
2. **Java version?** — Target Java 11 (matches Bazel) or Java 17 (LTS)?
3. **Flogger handling?** — Keep, stub, or replace with SLF4J?
4. **Test extraction?** — Include tests if dependencies are clean?
5. **REPL inclusion?** — Include cmd/Main.java as example/tool?

## References

- Bazel Starlark source: `bazelbuild/bazel/src/main/java/net/starlark/java/`
- Starlark spec: https://github.com/bazelbuild/starlark/blob/master/spec.md
- Copybara: https://github.com/google/copybara
