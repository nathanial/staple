import Lake
open Lake DSL

package staple where
  leanOptions := #[
    ⟨`autoImplicit, false⟩,
    ⟨`relaxedAutoImplicit, false⟩
  ]

@[default_target]
lean_lib Staple where
  roots := #[`Staple]
