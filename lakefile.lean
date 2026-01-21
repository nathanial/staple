import Lake
open Lake DSL

package staple where
  version := v!"0.0.3"
  leanOptions := #[
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

require crucible from git "https://github.com/nathanial/crucible" @ "v0.0.8"
require sift from git "https://github.com/nathanial/sift" @ "v0.0.4"

@[default_target]
lean_lib Staple where
  roots := #[`Staple]

lean_lib Tests where
  roots := #[`Tests]

@[test_driver]
lean_exe tests where
  root := `Tests
