import Mathlib.Tactic.Linter
import Mathlib.Tactic.SetNotationForOrder

/-!
# Verification commands

The snapshot is an explicit Lake input. This command compares the complete transitive
axioms of each reviewed declaration present in the imported environment. The complete
gate additionally rejects missing declarations; a narrow gate checks its imported portion.
-/

open Lean Elab Command

namespace Verification

/-- Split Lean's multiline reports without changing their bytes. -/
def snapshotEntries (text : String) : Except String (Array (Name × String)) := do
  unless text.startsWith "'" && text.endsWith "\n" do
    throw "snapshot must start with a declaration and end with a newline"
  let mut entries := #[]
  let mut seen : NameSet := {}
  for block in text.dropEnd 1 |>.toString.splitOn "\n'" do
    let block := if block.startsWith "'" then block else "'" ++ block
    let fields := block.splitOn "'"
    let ["", name, _] := fields | throw s!"malformed snapshot record: {block}"
    let name := name.toName
    if seen.contains name then throw s!"duplicate snapshot declaration: {name}"
    seen := seen.insert name
    entries := entries.push (name, block)
  return entries

/-- Check the reviewed reports against the declarations imported by this target. -/
elab (name := verifyAxiomsCommand)
    "verify_axioms " path:str mode:ident : command => do
  let complete ← match mode.getId with
    | `complete => pure true
    | `present => pure false
    | _ => throwErrorAt mode "expected complete or present"
  let entries ← match snapshotEntries (← IO.FS.readFile path.getString) with
    | .ok entries => pure entries
    | .error message => throwError "{message}"
  if entries.isEmpty then throwError "empty verification snapshot"
  let env ← getEnv
  let mut checked := 0
  for (name, expected) in entries do
    if env.contains name then
      let dependencies ← collectAxioms name
      let message := if dependencies.isEmpty then
        m!"'{name}' does not depend on any axioms"
      else
        let names := dependencies.qsort Name.lt |>.map MessageData.ofConstName |>.toList
        m!"'{name}' depends on axioms: {names}"
      let actual ← message.toString
      unless actual == expected do
        throwError "transitive axioms changed:\nexpected: {expected}\nactual:   {actual}"
      checked := checked + 1
      logInfo message
    else if complete then
      throwError "reviewed declaration absent: {name}"
  if checked == 0 then throwError "target imports no reviewed declarations"

open Batteries.Tactic.Lint in
/-- Run every default environment linter, including slow checks, over the named packages. -/
elab (name := verifyEnvironmentCommand) "verify_environment " packages:ident* : command => do
  let linters ← liftCoreM <| getChecks (slow := true) none none
  if linters.isEmpty then throwError "no environment linters loaded"
  for package in packages do
    let name := package.getId
    let declarations ← liftCoreM <| getDeclsInPackage name
    let results ← liftCoreM <| lintCore declarations linters
    if results.any (!·.2.isEmpty) then
      let report ← liftCoreM <| formatLinterResults results declarations
        (groupByFilename := true) s!"in {name}" (runSlowLinters := true) .low linters.size
      throwError report

end Verification
