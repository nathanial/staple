# Roadmap

This document tracks potential improvements, new features, and code cleanup opportunities for the Staple utilities library.

## Feature Proposals

### [Priority: High] include_bytes% Macro for Binary File Embedding

**Description:** Add a companion macro to `include_str%` that embeds binary files as `ByteArray` at compile time.

**Rationale:** Several projects in the workspace (raster, afferent, assimptor) work with binary data like images, fonts, or model files. Currently, binary assets must be loaded at runtime. A compile-time binary embedding macro would enable:
- Bundling small binary assets directly into executables
- Avoiding runtime file I/O for embedded resources
- Consistent pattern with `include_str%` for string resources

**Affected Files:**
- `Staple/IncludeBytes.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Small

**Implementation Notes:**
```lean
-- Proposed API
def myIcon : ByteArray := include_bytes% "assets/icon.png"
```

---

### [Priority: High] Additional ToJsonStr Instances

**Description:** Expand the `ToJsonStr` typeclass with instances for commonly used types in the workspace.

**Rationale:** Current instances cover `String`, `Nat`, `Int`, `Bool`, `Float`, and `UInt64`. Projects using `jsonStr!` frequently need to serialize additional types. Missing instances that would be valuable:
- `Option α` (renders as `null` or the wrapped value)
- `Array α` / `List α` (renders as JSON arrays)
- `UInt8`, `UInt16`, `UInt32`, `Int8`, `Int16`, `Int32`, `Int64`
- Potentially a `Json` instance for embedding raw JSON

**Affected Files:**
- `Staple/Json.lean`

**Estimated Effort:** Small

**Implementation Notes:**
```lean
instance [ToJsonStr α] : ToJsonStr (Option α) where
  toJsonStr
  | none => "null"
  | some a => ToJsonStr.toJsonStr a

instance [ToJsonStr α] : ToJsonStr (Array α) where
  toJsonStr arr := "[" ++ (arr.toList.map ToJsonStr.toJsonStr |> String.intercalate ", ") ++ "]"
```

---

### [Priority: Medium] String Utility Expansion

**Description:** Add commonly needed string manipulation functions beyond `containsSubstr`.

**Rationale:** Analysis of the workspace shows repeated patterns that could be consolidated:
- `String.trim` is used but is built-in
- Padding functions for formatted output
- String splitting with limit
- Case conversion helpers

**Proposed Functions:**
- `String.padLeft : String -> Nat -> Char -> String`
- `String.padRight : String -> Nat -> Char -> String`
- `String.splitFirst : String -> String -> Option (String x String)`
- `String.splitLast : String -> String -> Option (String x String)`
- `String.removePrefix : String -> String -> String`
- `String.removeSuffix : String -> String -> String`
- `String.truncate : String -> Nat -> String -> String` (with ellipsis)

**Affected Files:**
- `Staple/String.lean`

**Estimated Effort:** Medium

---

### [Priority: Medium] include_dir% Macro for Directory Embedding

**Description:** Add a macro that embeds all files from a directory as an `Array (String x String)` of (filename, contents) pairs.

**Rationale:** Projects like afferent embed multiple shader files individually. A directory embedding macro would simplify this pattern.

**Affected Files:**
- `Staple/IncludeDir.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Medium

**Implementation Notes:**
```lean
-- Proposed API
def shaders : Array (String x String) := include_dir% "shaders/"
-- Returns: #[("basic.metal", "..."), ("text.metal", "..."), ...]
```

---

### [Priority: Medium] Result/Either Type and Utilities

**Description:** Add a polymorphic `Result` type with common combinators.

**Rationale:** While Lean has `Except`, a lightweight `Result` type with ergonomic combinators would be useful for error handling in pure code without the full `ExceptT` machinery.

**Proposed API:**
- `Result.map`, `Result.mapError`
- `Result.flatMap`, `Result.flatten`
- `Result.toOption`, `Result.fromOption`
- `Result.unwrapOr`, `Result.unwrapOrElse`
- `Result.isOk`, `Result.isErr`

**Affected Files:**
- `Staple/Result.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Small

---

### [Priority: Low] Memoization Utilities

**Description:** Add simple memoization helpers for pure functions.

**Rationale:** Several projects perform repeated computations that could benefit from memoization. A simple caching utility would reduce boilerplate.

**Affected Files:**
- `Staple/Memo.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Medium

---

### [Priority: Low] Debug/Trace Utilities

**Description:** Add debugging helpers that can be easily enabled/disabled.

**Rationale:** Consistent debugging patterns across projects would improve development experience.

**Proposed Functions:**
- `dbgTrace : String -> α -> α` (conditional based on compile flag)
- `dbgTime : String -> IO α -> IO α` (timing wrapper)
- `assertM : Bool -> String -> m Unit` (monadic assertion)

**Affected Files:**
- `Staple/Debug.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Small

---

## Code Improvements

### [Priority: High] Optimize String.containsSubstr Implementation

**Current State:** The current implementation uses `splitOn` which allocates a list of substrings just to check for existence:
```lean
def String.containsSubstr (haystack needle : String) : Bool :=
  (haystack.splitOn needle).length > 1
```

**Proposed Change:** Use a more efficient substring search that returns early without allocating:
```lean
def String.containsSubstr (haystack needle : String) : Bool :=
  haystack.findSubstr? needle |>.isSome
-- Or implement a direct Boyer-Moore/KMP if findSubstr? doesn't exist
```

**Benefits:** Reduced memory allocations, faster early termination on match.

**Affected Files:**
- `Staple/String.lean`

**Estimated Effort:** Small

---

### [Priority: Medium] Add Error Handling to include_str%

**Current State:** The `include_str%` macro will fail with an opaque IO error if the file doesn't exist.

**Proposed Change:** Provide a clearer error message that includes the resolved file path and suggestions.

**Benefits:** Better developer experience when paths are incorrect.

**Affected Files:**
- `Staple/IncludeStr.lean`

**Estimated Effort:** Small

**Implementation Notes:**
```lean
elab "include_str% " path:str : term => do
  let ctx ← readThe Core.Context
  let srcPath := ctx.fileName
  let srcDir := System.FilePath.parent srcPath |>.getD ""
  let filePath := srcDir / path.getString
  if !(← filePath.pathExists) then
    throwError s!"include_str%: File not found: {filePath}\n  (resolved from {path.getString} relative to {srcPath})"
  let contents ← IO.FS.readFile filePath
  return mkStrLit contents
```

---

### [Priority: Medium] escapeString Performance

**Current State:** The `escapeString` function in `Json.lean` iterates character-by-character and builds up a string with repeated concatenation.

**Proposed Change:** Use a more efficient approach:
- Pre-scan to determine if escaping is needed at all
- Use `String.Builder` or array-based accumulation
- Handle the common case (no escaping needed) with an early return

**Benefits:** Improved performance for JSON generation in hot paths.

**Affected Files:**
- `Staple/Json.lean`

**Estimated Effort:** Small

---

### [Priority: Low] Consolidate Duplicate escapeString Implementations

**Current State:** Multiple projects have their own `escapeString` implementations:
- `Staple/Json.lean`
- `Chisel/Core/Literal.lean`
- `Ledger/Persist/JSON.lean`

**Proposed Change:** Export `Staple.Json.escapeString` more prominently and update other projects to use it.

**Benefits:** Reduced code duplication, single source of truth for JSON escaping.

**Affected Files:**
- `Staple/Json.lean` (documentation)
- External projects (chisel, ledger) would need updates

**Estimated Effort:** Small (Staple changes) + Medium (coordinating downstream)

---

## Code Cleanup

### [Priority: High] Update Documentation for New Modules

**Issue:** The CLAUDE.md and README.md only document `IncludeStr.lean` but the library now includes `String.lean` and `Json.lean`.

**Location:**
- `/Users/Shared/Projects/lean-workspace/util/staple/CLAUDE.md`
- `/Users/Shared/Projects/lean-workspace/util/staple/README.md`

**Action Required:**
1. Update CLAUDE.md project structure to list all modules
2. Update README.md to document `jsonStr!` macro and string utilities
3. Add usage examples for all features

**Estimated Effort:** Small

---

### [Priority: Medium] Add Test Suite

**Issue:** Staple has no test suite. As a foundational library used by 15+ projects, it should have comprehensive tests.

**Location:** Project root (needs new files)

**Action Required:**
1. Add crucible as a dev dependency
2. Create `Tests/Main.lean` with test cases for:
   - `String.containsSubstr` edge cases (empty strings, Unicode)
   - `jsonStr!` macro with various types
   - `ToJsonStr` instances
   - `escapeString` with special characters
   - `include_str%` behavior (would need test fixture files)

**Estimated Effort:** Medium

---

### [Priority: Medium] Add Module-Level Documentation

**Issue:** The modules have brief header comments but lack comprehensive documentation for the public API.

**Location:**
- `Staple/IncludeStr.lean`
- `Staple/String.lean`
- `Staple/Json.lean`

**Action Required:**
1. Add docstrings to all public functions
2. Add module-level documentation with examples
3. Consider adding a `#check` example block

**Estimated Effort:** Small

---

### [Priority: Low] Namespace Consistency

**Issue:** The library uses mixed namespace patterns:
- `include_str%` is defined in `Staple` namespace (good, short access)
- `jsonStr!` is defined outside namespace (in `Staple.Json`)
- `String.containsSubstr` is defined in `Staple` namespace

**Location:**
- `Staple/IncludeStr.lean`
- `Staple/String.lean`
- `Staple/Json.lean`

**Action Required:**
1. Decide on consistent namespace strategy
2. Either move all macros to root for ergonomic access, or document the full paths
3. Consider re-exporting common functions in the root `Staple` namespace

**Estimated Effort:** Small

---

## Architecture Considerations

### Tier 0 Dependency Status

Staple is a Tier 0 (leaf) dependency with no external requirements. This is intentional and should be preserved. Any new features should:

1. Not add external dependencies
2. Remain focused on compile-time utilities and essential helpers
3. Avoid domain-specific functionality that belongs in specialized libraries

### Downstream Impact

As of the analysis, 15 projects depend on staple:
- apps: homebase-app, enchiridion
- graphics: arbor, raster, grove, tincture, afferent
- web: loom, citadel
- data: chisel, ledger, quarry
- network: wisp
- util: docgen, parlance

Any breaking changes require coordinated updates across all downstream projects.

### Feature Boundary Guidelines

**Should be in Staple:**
- Compile-time macros (`include_str%`, `include_bytes%`)
- Universal string utilities
- Basic JSON string generation
- General-purpose debugging helpers

**Should NOT be in Staple:**
- Parsing logic (belongs in specialized parsers)
- I/O utilities beyond file embedding
- Type-specific serialization (belongs in domain libraries)
- Complex data structures (belongs in batteries or specialized libs)
