/-
  Tests for Staple.Json
-/
import Crucible
import Staple.Json

namespace Tests.Json

open Crucible
open Staple.Json

testSuite "Staple.Json"

test "escapeString - no escaping" := do
  (escapeString "hello") ≡ "hello"
  (escapeString "abc123") ≡ "abc123"

test "escapeString - quotes" := do
  (escapeString "say \"hi\"") ≡ "say \\\"hi\\\""

test "escapeString - backslash" := do
  (escapeString "a\\b") ≡ "a\\\\b"

test "escapeString - control chars" := do
  (escapeString "line\nbreak") ≡ "line\\nbreak"
  (escapeString "tab\there") ≡ "tab\\there"
  (escapeString "return\rhere") ≡ "return\\rhere"

test "ToJsonStr - String" := do
  (ToJsonStr.toJsonStr "hello") ≡ "\"hello\""
  (ToJsonStr.toJsonStr "") ≡ "\"\""

test "ToJsonStr - Nat" := do
  (ToJsonStr.toJsonStr (0 : Nat)) ≡ "0"
  (ToJsonStr.toJsonStr (42 : Nat)) ≡ "42"

test "ToJsonStr - Int" := do
  (ToJsonStr.toJsonStr (42 : Int)) ≡ "42"
  (ToJsonStr.toJsonStr (-42 : Int)) ≡ "-42"

test "ToJsonStr - Bool" := do
  (ToJsonStr.toJsonStr true) ≡ "true"
  (ToJsonStr.toJsonStr false) ≡ "false"

test "ToJsonStr - Option" := do
  (ToJsonStr.toJsonStr (some 42 : Option Nat)) ≡ "42"
  (ToJsonStr.toJsonStr (none : Option Nat)) ≡ "null"

test "ToJsonStr - Array" := do
  (ToJsonStr.toJsonStr #[1, 2, 3]) ≡ "[1, 2, 3]"
  (ToJsonStr.toJsonStr (#[] : Array Nat)) ≡ "[]"

test "ToJsonStr - List" := do
  (ToJsonStr.toJsonStr [1, 2, 3]) ≡ "[1, 2, 3]"
  (ToJsonStr.toJsonStr ([] : List Nat)) ≡ "[]"

test "ToJsonStr - UInt8" := do
  (ToJsonStr.toJsonStr (255 : UInt8)) ≡ "255"
  (ToJsonStr.toJsonStr (0 : UInt8)) ≡ "0"

test "jsonStr! - shorthand" := do
  let name := "Alice"
  let age : Nat := 30
  (jsonStr! { name, age }) ≡ "{\"name\": \"Alice\", \"age\": 30}"

test "jsonStr! - explicit keys" := do
  let x : Nat := 10
  (jsonStr! { "value" : x }) ≡ "{\"value\": 10}"

test "jsonStr! - mixed" := do
  let name := "Bob"
  let score : Nat := 100
  (jsonStr! { name, "points" : score }) ≡ "{\"name\": \"Bob\", \"points\": 100}"

#generate_tests

end Tests.Json
