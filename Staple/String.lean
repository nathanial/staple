/-
  Staple.String - String utilities
-/
namespace Staple

/-- Check if `haystack` contains `needle` as a substring. -/
def String.containsSubstr (haystack needle : String) : Bool :=
  (haystack.splitOn needle).length > 1

end Staple
