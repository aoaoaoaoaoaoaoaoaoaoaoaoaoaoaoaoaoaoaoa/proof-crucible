import Lake

open Lake DSL System Lean

package campaign where
  version := v!"0.1.0"
  enableArtifactCache := true
  restoreAllArtifacts := true
  leanOptions := #[
    ⟨`warningAsError, true⟩, ⟨`autoImplicit, false⟩, ⟨`pp.unicode.fun, true⟩,
    ⟨`linter.docPrime, true⟩, ⟨`linter.hashCommand, true⟩, ⟨`linter.oldObtain, true⟩,
    ⟨`linter.style.refine, true⟩, ⟨`linter.style.cdot, true⟩,
    ⟨`linter.style.dollarSyntax, true⟩, ⟨`linter.style.lambdaSyntax, true⟩,
    ⟨`linter.style.longFile, 1500⟩, ⟨`linter.style.longLine, true⟩,
    ⟨`linter.style.missingEnd, true⟩, ⟨`linter.style.setOption, true⟩]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git" @ "v4.33.1"

@[default_target]
lean_lib Campaign where
  globs := #[.andSubmodules `Campaign]

lean_lib Verification where
  globs := #[.submodules `Verification]

namespace Gate

/-- Resolve a verification root through Lake. -/
def module (name : Name) : FetchM Lake.Module := do
  let some mod := (← getWorkspace).findModule? name
    | error s!"unknown verification root: {name}"
  return mod

/-- Compile, scan, lint, and compare the complete reviewed axiom surface. -/
def proof (pkg : Package) (label : String) (roots : Array Name)
    (complete := false) : FetchM (Job FilePath) := withCurrPackage pkg do
  let modules ← if complete then
    Array.flatten <$> pkg.leanLibs.mapM (·.getModuleArray)
  else
    roots.mapM module
  let modules := modules.qsort (fun a b => a.name.lt b.name)
  let roots := modules.map (·.name)
  let audit ← module `Verification.Audit
  let imports ← Job.collectArray <$> modules.mapM (·.transImports.fetch)
  let imported ← imports.await
  let mut closure := #[]
  let mut seen : NameSet := {}
  for mod in imported.flatten ++ modules.push audit do
    if mod.pkg.keyName == pkg.keyName && !seen.contains mod.name then
      seen := seen.insert mod.name
      closure := closure.push mod
  let sources := (closure.map (·.leanFile)).toList.mergeSort (fun a b =>
    a.toString ≤ b.toString) |>.toArray
  let files := sources ++ #[pkg.dir / "lakefile.lean",
    pkg.dir / "verification/axioms.txt", pkg.dir / "scripts/check-proof-sources.sh",
    pkg.dir / "scripts/scan-lean-sources.py"]
  let inputs := Job.mixArray (← files.mapM (inputTextFile ·))
  let artifacts := Job.mixArray (← (modules.push audit).mapM (·.leanArts.fetch))
  (inputs.mix artifacts).mapM fun _ => do
    addLeanTrace
    addPureTrace (label, roots, complete) "verification contract"
    addPureTrace (closure.map (·.name)) "audited module inventory"
    let out := pkg.buildDir / "verification" / s!"{label}.txt"
    let result ← buildArtifactUnlessUpToDate out (text := true) (restore := true) do
      createParentDirs out
      proc {cmd := "bash", args := #["scripts/check-proof-sources.sh"] ++
        sources.map (·.toString), cwd := some pkg.dir}
      let auditFile := pkg.buildDir / "verification" / s!"{label}.lean"
      let header := String.join ((roots.push `Verification.Audit).toList.map
        (fun root => s!"import {root}\n"))
      IO.FS.writeFile auditFile <| header ++
        s!"\nverify_axioms \"verification/axioms.txt\" {if complete then "complete" else "present"}\n" ++
        "verify_environment Campaign Verification\n"
      let lean ← getLean
      let leanPath ← getLeanPath
      let options ← getLeanOptions
      let leanArgs := options.values.toArray.map fun (name, value) =>
        LeanOption.asCliArg ⟨name, value⟩
      let output ← captureProc' {
        cmd := lean.toString
        args := leanArgs.push auditFile.toString
        cwd := some pkg.dir
        env := #[("LEAN_PATH", some leanPath.toString)]
      }
      if complete && output.stdout != (← IO.FS.readFile (pkg.dir / "verification/axioms.txt")) then
        error "complete verification output differs from the reviewed snapshot"
      IO.FS.writeFile out output.stdout
    return result.path

end Gate

target proofs pkg : FilePath :=
  Gate.proof pkg "proofs" #[`Campaign] (complete := true)
