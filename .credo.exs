# Overlay on Credo's defaults: `extra` tunes params, `disabled` records
# deliberate style choices; new checks in future releases stay active.
%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          # One conditional inside a case is fine; default max_nesting 2 is too strict
          {Credo.Check.Refactor.Nesting, [max_nesting: 3]},
          # quantizer_test's zero-padding for column alignment trips this check
          {Credo.Check.Readability.LargeNumbers,
           [files: %{excluded: ["test/asciinema/quantizer_test.exs"]}]}
        ],
        disabled: [
          # Occasional fully-qualified nested module calls are established style here
          {Credo.Check.Design.AliasUsage, []},
          # this codebase does not write @moduledoc
          {Credo.Check.Readability.ModuleDoc, []},
          # Explicit try/after around resource cleanup is established style here
          {Credo.Check.Readability.PreferImplicitTry, []},
          # Single-clause with/else (happy path first) is a pervasive idiom here
          {Credo.Check.Readability.WithSingleClause, []},
          # pattern-match-heavy parsers/query builders read fine at complexity 10-33
          {Credo.Check.Refactor.CyclomaticComplexity, []}
        ]
      }
    }
  ]
}
