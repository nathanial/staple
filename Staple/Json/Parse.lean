/-
  Staple.Json.Parse - JSON parser

  A recursive descent parser for JSON per RFC 8259.
-/
import Staple.Json.Value

namespace Staple.Json

/-- Parser state: remaining input and current position -/
structure ParseState where
  input : String
  pos : Nat
  deriving Repr

/-- Parser error with position information -/
structure ParseError where
  message : String
  pos : Nat
  deriving Repr, BEq

instance : ToString ParseError where
  toString e := s!"JSON parse error at position {e.pos}: {e.message}"

/-- Parser result type -/
abbrev ParseResult (α : Type) := Except ParseError (α × ParseState)

/-- Get character at position, if valid -/
private def charAt (s : String) (pos : Nat) : Option Char :=
  if pos < s.length then some (s.get ⟨pos⟩) else none

/-- Skip whitespace from current position -/
private def skipWhitespace (state : ParseState) : ParseState :=
  let rec go (pos : Nat) (fuel : Nat) : Nat :=
    match fuel with
    | 0 => pos
    | fuel + 1 =>
      match charAt state.input pos with
      | some c =>
        if c == ' ' || c == '\n' || c == '\r' || c == '\t' then
          go (pos + 1) fuel
        else pos
      | none => pos
  { state with pos := go state.pos state.input.length }

/-- Parse error at current position -/
private def parseError {α : Type} (msg : String) (state : ParseState) : ParseResult α :=
  .error { message := msg, pos := state.pos }

/-- Expect a specific character -/
private def expectChar (expected : Char) (state : ParseState) : ParseResult Char :=
  match charAt state.input state.pos with
  | some c =>
    if c == expected then .ok (c, { state with pos := state.pos + 1 })
    else parseError s!"Expected '{expected}', got '{c}'" state
  | none => parseError s!"Expected '{expected}', got end of input" state

/-- Expect a specific string -/
private def expectString (expected : String) (state : ParseState) : ParseResult String :=
  let rec go (idx : Nat) (pos : Nat) : ParseResult String :=
    if idx >= expected.length then
      .ok (expected, { state with pos := pos })
    else
      match charAt state.input pos, charAt expected idx with
      | some c, some ec =>
        if c == ec then go (idx + 1) (pos + 1)
        else parseError s!"Expected '{expected}'" state
      | _, _ => parseError s!"Expected '{expected}', got end of input" state
  go 0 state.pos

/-- Parse a hex digit -/
private def hexDigit (c : Char) : Option Nat :=
  if '0' ≤ c ∧ c ≤ '9' then some (c.toNat - '0'.toNat)
  else if 'a' ≤ c ∧ c ≤ 'f' then some (c.toNat - 'a'.toNat + 10)
  else if 'A' ≤ c ∧ c ≤ 'F' then some (c.toNat - 'A'.toNat + 10)
  else none

/-- Parse a JSON string literal -/
private def parseStringLit (state : ParseState) : ParseResult String :=
  match expectChar '"' state with
  | .error e => .error e
  | .ok (_, state) =>
    let rec go (acc : String) (pos : Nat) (fuel : Nat) : ParseResult String :=
      match fuel with
      | 0 => parseError "String too long" { state with pos }
      | fuel + 1 =>
        match charAt state.input pos with
        | none => parseError "Unterminated string" { state with pos }
        | some '"' => .ok (acc, { state with pos := pos + 1 })
        | some '\\' =>
          match charAt state.input (pos + 1) with
          | none => parseError "Unterminated escape" { state with pos }
          | some 'n' => go (acc.push '\n') (pos + 2) fuel
          | some 'r' => go (acc.push '\r') (pos + 2) fuel
          | some 't' => go (acc.push '\t') (pos + 2) fuel
          | some '"' => go (acc.push '"') (pos + 2) fuel
          | some '\\' => go (acc.push '\\') (pos + 2) fuel
          | some '/' => go (acc.push '/') (pos + 2) fuel
          | some 'b' => go (acc.push '\x08') (pos + 2) fuel
          | some 'f' => go (acc.push '\x0C') (pos + 2) fuel
          | some 'u' =>
            match charAt state.input (pos+2), charAt state.input (pos+3),
                  charAt state.input (pos+4), charAt state.input (pos+5) with
            | some c1, some c2, some c3, some c4 =>
              match hexDigit c1, hexDigit c2, hexDigit c3, hexDigit c4 with
              | some d1, some d2, some d3, some d4 =>
                let codepoint := d1 * 4096 + d2 * 256 + d3 * 16 + d4
                go (acc.push (Char.ofNat codepoint)) (pos + 6) fuel
              | _, _, _, _ => parseError "Invalid unicode escape" { state with pos := pos + 2 }
            | _, _, _, _ => parseError "Incomplete unicode escape" { state with pos := pos + 2 }
          | some c => parseError s!"Invalid escape '\\{c}'" { state with pos }
        | some c => go (acc.push c) (pos + 1) fuel
    go "" state.pos (state.input.length * 2 + 1)

/-- Parse a JSON number -/
private def parseNumber (state : ParseState) : ParseResult JsonNumber :=
  let startPos := state.pos

  -- Collect digits from a position
  let rec collectDigits (pos : Nat) (fuel : Nat) : Nat :=
    match fuel with
    | 0 => pos
    | fuel + 1 =>
      match charAt state.input pos with
      | some c =>
        if '0' ≤ c ∧ c ≤ '9' then collectDigits (pos + 1) fuel
        else pos
      | none => pos

  -- Check for negative
  let (negative, pos) :=
    match charAt state.input state.pos with
    | some '-' => (true, state.pos + 1)
    | _ => (false, state.pos)

  -- Integer part
  let intEnd := collectDigits pos state.input.length
  if intEnd == pos then
    parseError "Expected digit" { state with pos }
  else
    -- Fraction part
    let (hasFrac, fracEnd) :=
      match charAt state.input intEnd with
      | some '.' =>
        let fe := collectDigits (intEnd + 1) state.input.length
        if fe == intEnd + 1 then (false, intEnd)
        else (true, fe)
      | _ => (false, intEnd)

    -- Exponent part
    let (hasExp, expEnd) :=
      match charAt state.input fracEnd with
      | some 'e' | some 'E' =>
        let signPos := match charAt state.input (fracEnd + 1) with
          | some '+' | some '-' => fracEnd + 2
          | _ => fracEnd + 1
        let ee := collectDigits signPos state.input.length
        if ee == signPos then (false, fracEnd)
        else (true, ee)
      | _ => (false, fracEnd)

    let finalState := { state with pos := expEnd }

    if hasFrac || hasExp then
      -- Float - parse via string
      let numStr := (state.input.toSubstring.drop startPos).take (expEnd - startPos) |>.toString
      -- Simple float parsing
      let f := parseFloatSimple numStr
      .ok (.float f, finalState)
    else
      -- Integer
      let intStr := (state.input.toSubstring.drop startPos).take (expEnd - startPos) |>.toString
      let absStr := if negative then intStr.drop 1 else intStr
      let value := absStr.foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0
      let signedValue : Int := if negative then -value else value
      .ok (.int signedValue, finalState)
where
  parseFloatSimple (s : String) : Float :=
    -- Use a helper to collect digits as Nat
    let collectNat (chars : List Char) : Nat × List Char :=
      chars.foldl (init := (0, [])) fun (acc, _) c =>
        if '0' ≤ c ∧ c ≤ '9' then (acc * 10 + (c.toNat - '0'.toNat), [])
        else (acc, chars)
      |> fun (n, _) => (n, chars.dropWhile (fun c => '0' ≤ c ∧ c ≤ '9'))

    let chars := s.toList
    let (neg, chars) := match chars with
      | '-' :: rest => (true, rest)
      | _ => (false, chars)

    -- Parse integer part
    let intDigits := chars.takeWhile (fun c => '0' ≤ c ∧ c ≤ '9')
    let intPart : Float := intDigits.foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat).toFloat) 0
    let chars := chars.drop intDigits.length

    -- Parse fractional part
    let (fracPart, chars) : Float × List Char := match chars with
      | '.' :: rest =>
        let fracDigits := rest.takeWhile (fun c => '0' ≤ c ∧ c ≤ '9')
        let (frac, _) := fracDigits.foldl (fun (acc, div) c =>
          (acc + (c.toNat - '0'.toNat).toFloat / div, div * 10)) (0.0, 10.0)
        (frac, rest.drop fracDigits.length)
      | _ => (0, chars)

    -- Parse exponent
    let exp : Int := match chars with
      | 'e' :: rest | 'E' :: rest =>
        let (expNeg, rest) := match rest with
          | '-' :: r => (true, r)
          | '+' :: r => (false, r)
          | _ => (false, rest)
        let expDigits := rest.takeWhile (fun c => '0' ≤ c ∧ c ≤ '9')
        let e : Nat := expDigits.foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0
        if expNeg then -(e : Int) else (e : Int)
      | _ => 0

    let base := intPart + fracPart
    let result := if exp >= 0 then
      base * Float.pow 10 exp.toNat.toFloat
    else
      base / Float.pow 10 ((-exp).toNat).toFloat
    if neg then -result else result

/-- Parse a JSON value -/
partial def parseValue (state : ParseState) : ParseResult Value :=
  let state := skipWhitespace state
  match charAt state.input state.pos with
  | none => parseError "Unexpected end of input" state
  | some 'n' =>
    match expectString "null" state with
    | .error e => .error e
    | .ok (_, state) => .ok (.null, state)
  | some 't' =>
    match expectString "true" state with
    | .error e => .error e
    | .ok (_, state) => .ok (.bool true, state)
  | some 'f' =>
    match expectString "false" state with
    | .error e => .error e
    | .ok (_, state) => .ok (.bool false, state)
  | some '"' =>
    match parseStringLit state with
    | .error e => .error e
    | .ok (s, state) => .ok (.str s, state)
  | some '[' => parseArray state
  | some '{' => parseObject state
  | some c =>
    if c == '-' || ('0' ≤ c ∧ c ≤ '9') then
      match parseNumber state with
      | .error e => .error e
      | .ok (n, state) => .ok (.num n, state)
    else
      parseError s!"Unexpected character '{c}'" state
where
  parseArray (state : ParseState) : ParseResult Value :=
    match expectChar '[' state with
    | .error e => .error e
    | .ok (_, state) =>
      let state := skipWhitespace state
      match charAt state.input state.pos with
      | some ']' => .ok (.arr #[], { state with pos := state.pos + 1 })
      | _ =>
        let rec go (items : Array Value) (state : ParseState) (fuel : Nat) : ParseResult Value :=
          match fuel with
          | 0 => parseError "Array too deep" state
          | fuel + 1 =>
            match parseValue state with
            | .error e => .error e
            | .ok (v, state) =>
              let items := items.push v
              let state := skipWhitespace state
              match charAt state.input state.pos with
              | some ',' =>
                let state := skipWhitespace { state with pos := state.pos + 1 }
                go items state fuel
              | some ']' => .ok (.arr items, { state with pos := state.pos + 1 })
              | _ => parseError "Expected ',' or ']'" state
        go #[] state 10000

  parseObject (state : ParseState) : ParseResult Value :=
    match expectChar '{' state with
    | .error e => .error e
    | .ok (_, state) =>
      let state := skipWhitespace state
      match charAt state.input state.pos with
      | some '}' => .ok (.obj #[], { state with pos := state.pos + 1 })
      | _ =>
        let rec go (fields : Array (String × Value)) (state : ParseState) (fuel : Nat) : ParseResult Value :=
          match fuel with
          | 0 => parseError "Object too deep" state
          | fuel + 1 =>
            let state := skipWhitespace state
            match parseStringLit state with
            | .error e => .error e
            | .ok (key, state) =>
              let state := skipWhitespace state
              match expectChar ':' state with
              | .error e => .error e
              | .ok (_, state) =>
                match parseValue state with
                | .error e => .error e
                | .ok (value, state) =>
                  let fields := fields.push (key, value)
                  let state := skipWhitespace state
                  match charAt state.input state.pos with
                  | some ',' =>
                    let state := skipWhitespace { state with pos := state.pos + 1 }
                    go fields state fuel
                  | some '}' => .ok (.obj fields, { state with pos := state.pos + 1 })
                  | _ => parseError "Expected ',' or '}'" state
        go #[] state 10000

/-- Parse a JSON string into a Value -/
def parse (input : String) : Except String Value :=
  let state : ParseState := { input := input, pos := 0 }
  match parseValue state with
  | .ok (value, finalState) =>
    let finalState := skipWhitespace finalState
    if finalState.pos >= finalState.input.length then
      .ok value
    else
      .error s!"Unexpected trailing content at position {finalState.pos}"
  | .error e => .error (toString e)

/-- Parse a JSON string, returning Option -/
def parse? (input : String) : Option Value :=
  match parse input with
  | .ok v => some v
  | .error _ => none

end Staple.Json
