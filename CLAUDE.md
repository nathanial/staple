# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Staple is a Lean 4 utilities library providing commonly-used macros and helpers for other projects in the workspace.

## Build Commands

```bash
lake build    # Build the library
```

## Project Structure

```
staple/
├── lakefile.lean         # Lake build configuration
├── lean-toolchain        # Lean version (v4.26.0)
├── Staple.lean           # Root module (imports all submodules)
└── Staple/
    └── IncludeStr.lean   # Compile-time file embedding macro
```

## Key Modules

### IncludeStr.lean

Provides `include_str%` macro for compile-time file embedding:

```lean
import Staple

def template : String := include_str% "path/to/file.html"
```

- Path is relative to the source file containing the macro call
- File is read at compile time and embedded as a string literal
- Useful for embedding HTML templates, SQL queries, config files, etc.

## Adding New Utilities

When adding new utilities:

1. Create a new file in `Staple/` (e.g., `Staple/NewUtility.lean`)
2. Add `import Staple.NewUtility` to `Staple.lean`
3. Keep utilities focused and minimal - this is a foundational library

## Dependencies

None - Staple is a leaf dependency with no external requirements.
