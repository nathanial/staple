# Roadmap

This document tracks potential improvements, new features, and code cleanup opportunities for the Staple utilities library.

## Feature Proposals

### [Priority: High] Hex Encoding/Decoding Utilities (Staple.Hex)

**Description:** Add hex encoding and decoding utilities for characters, bytes, and byte arrays.

**Rationale:** This is the most duplicated utility across the workspace, appearing in 6+ projects with nearly identical implementations:

| Project | Location |
|---------|----------|
| tracer | `Tracer/Core/TraceId.lean:35-81`, `SpanId.lean:27-59` |
| tincture | `Tincture/Parse.lean:12-27` |
| chisel | `Chisel/Parser/Lexer.lean:210-218` |
| totem | `Totem/Parser/Primitives.lean:34-39` |
| herald | `Herald/Parser/Primitives.lean:64-68` |

**Proposed API:**
```lean
namespace Staple.Hex

/-- Convert a hex character ('0'-'9', 'a'-'f', 'A'-'F') to its numeric value. -/
def hexCharToNat (c : Char) : Option Nat

/-- Convert a value 0-15 to its lowercase hex character. -/
def nibbleToHexChar (n : Nat) : Char

/-- Check if a character is a valid hex digit. -/
def isHexDigit (c : Char) : Bool

/-- Encode a ByteArray as a lowercase hex string. -/
def ByteArray.toHex (bytes : ByteArray) : String

/-- Decode a hex string to a ByteArray. Returns none if invalid. -/
def ByteArray.fromHex (s : String) : Option ByteArray

/-- Encode a single byte as two hex characters. -/
def UInt8.toHex (b : UInt8) : String

end Staple.Hex
```

**Affected Files:**
- `Staple/Hex.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Small

**Best Reference Implementation:** `util/tracer/Tracer/Core/TraceId.lean` - cleanest with `Option` return types

---

### [Priority: High] ASCII Character Classification (Staple.Ascii)

**Description:** Add comprehensive ASCII character classification and case conversion utilities.

**Rationale:** Duplicated in 3+ projects with similar implementations:

| Project | Location |
|---------|----------|
| markup | `Markup/Core/Ascii.lean:7-76` (most complete) |
| totem | `Totem/Parser/Primitives.lean:11-32` |
| herald | `Herald/Parser/Primitives.lean:14-62` |

**Proposed API:**
```lean
namespace Staple.Ascii

-- Character classification
def isWhitespace (c : Char) : Bool  -- space, tab, newline, carriage return
def isAlpha (c : Char) : Bool       -- a-z, A-Z
def isDigit (c : Char) : Bool       -- 0-9
def isAlphaNum (c : Char) : Bool    -- alpha or digit
def isHexDigit (c : Char) : Bool    -- 0-9, a-f, A-F
def isOctalDigit (c : Char) : Bool  -- 0-7
def isBinaryDigit (c : Char) : Bool -- 0-1
def isPrintable (c : Char) : Bool   -- 0x20-0x7E

-- Case conversion
def toLower (c : Char) : Char
def toUpper (c : Char) : Char
def String.toLowerAscii (s : String) : String
def String.toUpperAscii (s : String) : String

-- UInt8 variants for byte-level parsing
def isDigitU8 (b : UInt8) : Bool
def isAlphaU8 (b : UInt8) : Bool
def isHexDigitU8 (b : UInt8) : Bool

end Staple.Ascii
```

**Affected Files:**
- `Staple/Ascii.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Small

**Best Reference Implementation:** `web/markup/Markup/Core/Ascii.lean` - most complete module

---

### [Priority: High] String Padding Utilities (Staple.StringPad)

**Description:** Add string padding and trimming utilities.

**Rationale:** Duplicated in 3+ projects:

| Project | Location |
|---------|----------|
| totem | `Totem/Core/Value.lean:8-15` |
| arbor | `Arbor/Text/Renderer.lean:19-22` |
| terminus | Various widget files |

**Proposed API:**
```lean
namespace Staple

/-- Pad a string on the left to reach the specified width. -/
def String.padLeft (s : String) (width : Nat) (c : Char := ' ') : String

/-- Pad a string on the right to reach the specified width. -/
def String.padRight (s : String) (width : Nat) (c : Char := ' ') : String

/-- Drop characters from the right while predicate holds. -/
def String.dropRightWhile (s : String) (p : Char → Bool) : String

/-- Drop characters from the left while predicate holds. -/
def String.dropLeftWhile (s : String) (p : Char → Bool) : String

end Staple
```

**Affected Files:**
- `Staple/String.lean` (extend existing)

**Estimated Effort:** Small

**Best Reference Implementation:** `data/totem/Totem/Core/Value.lean` - includes both padding and trimming

---

### [Priority: Medium] Conversion Utilities (Staple.Conversion)

**Description:** Add common type conversion utilities.

**Rationale:** Several projects implement similar conversion patterns:

| Project | Location |
|---------|----------|
| chisel | `Chisel/Parser/Lexer.lean:91-93` |
| terminus | `Terminus/Widgets/BigText.lean:17-18` |

**Proposed API:**
```lean
namespace Staple

/-- Convert a list of characters to a string efficiently. -/
def String.ofCharList (cs : List Char) : String

/-- Convert a list to an array. -/
def Array.ofList {α : Type} (xs : List α) : Array α

end Staple
```

**Affected Files:**
- `Staple/Conversion.lean` (new file)
- `Staple.lean` (add import)

**Estimated Effort:** Small

---

### [Priority: Medium] JSON Unescape Function

**Description:** Add `unescapeString` as complement to existing `escapeString`.

**Rationale:** Projects doing JSON parsing (loom, oracle, homebase-app) need to unescape JSON strings. Currently only escaping is provided.

**Proposed API:**
```lean
namespace Staple.Json

/-- Unescape a JSON string value, handling \\", \\\\, \\n, \\r, \\t, \\uXXXX. -/
def unescapeString (s : String) : Option String

end Staple.Json
```

**Affected Files:**
- `Staple/Json.lean`

**Estimated Effort:** Small

---

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

### [Priority: Medium] Additional String Utilities

**Description:** Add string manipulation functions beyond padding (see String Padding Utilities above).

**Rationale:** Analysis of the workspace shows repeated patterns that could be consolidated.

**Proposed Functions:**
- `String.splitFirst : String -> String -> Option (String × String)` - split at first occurrence
- `String.splitLast : String -> String -> Option (String × String)` - split at last occurrence
- `String.removePrefix : String -> String -> String` - remove prefix if present
- `String.removeSuffix : String -> String -> String` - remove suffix if present
- `String.truncate : String -> Nat -> String -> String` - truncate with ellipsis

**Affected Files:**
- `Staple/String.lean`

**Estimated Effort:** Small

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
