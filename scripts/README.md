# Retired alias migration

Run this script in PowerShell from the **checkout you intend to inspect or change**. It does not choose a checkout for you.

```powershell
.\scripts\Normalize-RetiredAliases.ps1
```

With no arguments, it prints help. Use `-Help` for the same message.

Preview first:

```powershell
.\scripts\Normalize-RetiredAliases.ps1 -Root . -LogPath .\Normalize-RetiredAliases.log
```

The preview does not edit source files. It prints changed files and every changed line before and after, and writes the full detail to the log. The log directory must already exist. `-All` also lists unchanged and skipped files.

After reviewing the log, apply the same migration:

```powershell
.\scripts\Normalize-RetiredAliases.ps1 -Root . -Apply -LogPath .\Normalize-RetiredAliases.log
```

`-Apply` edits source files in the selected root. It does not stage, commit, or push. Review `git diff` and run the relevant builds and tests afterward. Reusing the same log path replaces its previous contents, so choose separate paths if you want to retain both preview and apply logs.

If PowerShell blocks scripts under your current execution policy, run `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Normalize-RetiredAliases.ps1` followed by the same arguments. This changes the policy only for that process.

The script was tested on an isolated LLB baseline trial. Its second dry run proposed zero edits. The trial's samples solution built, but complete LLC and LLT solution builds had separate baseline blockers, and the full LLC core test run remains unresolved. See the Gatewatch trial record for those exact limits.
