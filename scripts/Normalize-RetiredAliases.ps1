param(
    [string[]]$Root,
    [switch]$Apply,
    [switch]$All,
    [switch]$Help,
    [string]$LogPath = (Join-Path (Get-Location).Path 'Normalize-RetiredAliases.log')
)

$ErrorActionPreference = 'Stop'
if($Help -or -not $Root) {
    @'
Normalize-RetiredAliases.ps1 [-Root <source-directory>] [-Apply] [-All] [-LogPath <log-file>] [-Help]

Without -Apply, previews changes without editing files. -Apply writes the changes.
-Root selects the checkout or source directory to scan; the script never selects one for you.
-LogPath writes the full per-file, before/after line log (default: ./Normalize-RetiredAliases.log).
-All also lists unchanged and skipped files. -Help shows this message.
The log directory must already exist. Review the preview and your Git diff before committing.
'@
    return
}
foreach($rootPath in $Root) { if(-not (Test-Path -LiteralPath $rootPath -PathType Container)) { throw "Missing source root: $rootPath" } }
$hasEventDeviceHeader = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'llc_event_device.h' -ErrorAction SilentlyContinue).Count -gt 0
$hasFrameworkModuleHeader = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'llc_framework_module.h' -ErrorAction SilentlyContinue).Count -gt 0
$logDirectory = Split-Path -Parent $LogPath
if($logDirectory -and -not (Test-Path -LiteralPath $logDirectory -PathType Container)) { throw "Missing log directory: $logDirectory" }
$logWriter = [System.IO.StreamWriter]::new($LogPath, $false, [System.Text.UTF8Encoding]::new($false))
$logWriter.AutoFlush = $true
function Write-Feedback([string]$message) {
    Write-Output $message
    $logWriter.WriteLine($message)
}
function Write-LineChanges([string]$before, [string]$after) {
    $oldLines = @([regex]::Split($before, '\r\n|\n|\r'))
    $newLines = @([regex]::Split($after, '\r\n|\n|\r'))
    $oldIndex = 0
    $newIndex = 0
    while($oldIndex -lt $oldLines.Count -or $newIndex -lt $newLines.Count) {
        if($oldIndex -lt $oldLines.Count -and $newIndex -lt $newLines.Count -and $oldLines[$oldIndex] -ceq $newLines[$newIndex]) { ++$oldIndex; ++$newIndex; continue }
        ++$script:changedLines
        if($oldIndex -ge $oldLines.Count -or ($newIndex + 1 -lt $newLines.Count -and $oldLines[$oldIndex] -ceq $newLines[$newIndex + 1])) {
            Write-Feedback ("  + after line {0}: {1}" -f ($newIndex + 1), $newLines[$newIndex])
            ++$newIndex
        }
        elseif($newIndex -ge $newLines.Count -or ($oldIndex + 1 -lt $oldLines.Count -and $oldLines[$oldIndex + 1] -ceq $newLines[$newIndex])) {
            Write-Feedback ("  - before line {0}: {1}" -f ($oldIndex + 1), $oldLines[$oldIndex])
            ++$oldIndex
        }
        else {
            Write-Feedback ("  - before line {0}: {1}" -f ($oldIndex + 1), $oldLines[$oldIndex])
            Write-Feedback ("  + after line {0}: {1}" -f ($newIndex + 1), $newLines[$newIndex])
            ++$oldIndex
            ++$newIndex
        }
    }
}
function Add-ConditionalFailureBraces([string]$source) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach($match in [regex]::Matches($source, '[^\r\n]*(?:\r\n|\n|\r|$)')) {
        if($match.Length) { $lines.Add($match.Value) }
    }
    for($i = $lines.Count - 1; $i -ge 1; --$i) {
        if($lines[$i] -notmatch '^(?<arm>[ \t]+)if_fail_[A-Za-z0-9_]+\([^\r\n]*\);[^\r\n]*(?:\r?\n)?$') { continue }
        $end = $i - 1
        $lastConditionLine = $lines[$end].TrimEnd([char[]]"`r`n")
        $closing = [regex]::Match($lastConditionLine, '^(?<head>.*\))[ \t]*(?<comment>//.*)?$')
        if(-not $closing.Success) { continue }
        $start = $end
        while($start -ge 0 -and $lines[$start] -notmatch '^[ \t]*(?:else\s+)?(?:if|if_failed)\s*\(') {
            if($lines[$start] -notmatch '^[ \t]*(?:\|\||&&|==|\))') { break }
            --$start
        }
        if($start -lt 0 -or $lines[$start] -notmatch '^(?<indent>[ \t]*)(?:else\s+)?(?:if|if_failed)\s*\(') { continue }
        $indent = $Matches['indent']
        $armIndent = [regex]::Match($lines[$i], '^[ \t]+').Value
        if($armIndent.Length -le $indent.Length) { continue }
        $newline = if($lines[$end].EndsWith("`r`n")) { "`r`n" } else { "`n" }
        $comment = $closing.Groups['comment'].Value
        $lines[$end] = $closing.Groups['head'].Value + ' {' + $(if($comment) { ' ' + $comment } else { '' }) + $newline
        $lines.Insert($i + 1, $indent + '}' + $newline)
    }
    return [string]::Concat($lines)
}
$map = [ordered]@{
    # Retired modifier spellings from llc_platform_globals.h.
    'cnstnxpt' = 'csnx'
    'cnstvltl' = 'csvl'
    'cnstxpr' = 'cxpr'
    'inlcxpr' = 'inxp'
    'ndcnxpr' = 'ndxp'
    'ndincxp' = 'ndix'
    'ndinlne' = 'ndin'
    'ndstain' = 'ndsi'
    'ndstcxp' = 'ndsx'
    'ndstinx' = 'nsix'
    'ndsttic' = 'ndst'
    'nodscrd' = 'ndsc'
    'operatr' = 'oper'
    'privte' = 'prvt'
    'prtctd' = 'prtc'
    'stacxpr' = 'stxp'
    'stainli' = 'stin'
    'stincxp' = 'sinx'
    'tplTndstcxp' = 'tplTndsx'
    'tplTndstinx' = 'tplTnsix'
    'tplTstacxpr' = 'tplTstxp'
    'tplTstincxp' = 'tplTsinx'
    'tplTstruct' = 'tplTstct'
    'unsgnd' = 'unsd'
    # Retired secondary names from llc_typeint.h.
    'b8u_t' = 'b8_t'
    'b8u_c' = 'b8_c'
    'c0s_t' = 'sc_t'
    'c0s_c' = 'sc_c'
    'c0u_t' = 'uc_t'
    'c0u_c' = 'uc_c'
    'i0s_t' = 's0_t'
    'i0s_c' = 's0_c'
    'i0u_t' = 'u0_t'
    'i0u_c' = 'u0_c'
    'i1s_t' = 's1_t'
    'i1s_c' = 's1_c'
    'i1u_t' = 'u1_t'
    'i1u_c' = 'u1_c'
    'i2s_t' = 's2_t'
    'i2s_c' = 's2_c'
    'i2u_t' = 'u2_t'
    'i2u_c' = 'u2_c'
    'i3s_t' = 's3_t'
    'i3s_c' = 's3_c'
    'i3u_t' = 'u3_t'
    'i3u_c' = 'u3_c'
    'f2s_t' = 'f2_t'
    'f2s_c' = 'f2_c'
    'f3s_t' = 'f3_t'
    'f3s_c' = 'f3_c'
    'iPu_t' = 'uP_t'
    'iPu_c' = 'uP_c'
    'iPs_t' = 'sP_t'
    'iVu_t' = 'uV_t'
    'error_t' = 'err_t'
    # Removed log aliases: replacements already exist in llc_log.h.
    'llc_necs' = 'if_fail_fe'
    'llc_necall' = 'if_fail_fef'
    'gthrow_if' = 'if_true_tef'
    'gsthrow_if' = 'if_true_te'
    'if_truif_true_e' = 'if_true_if'
    'tplN2uinxp' = 'tplN2u inxp'
    'kvvcst' = 'kvvcst_t'
    'astchar' = 'astsc_t'
    'astc' = 'astsc_t'
    'astaticc' = 'astsc_t'
    'astuc' = 'astuc_t'
    'astaticuc' = 'astuc_t'
    'astu8' = 'astu0_t'
    'astu16' = 'astu1_t'
    'astu32' = 'astu2_t'
    'astu64' = 'astu3_t'
    'asti8' = 'asts0_t'
    'asti16' = 'asts1_t'
    'asti32' = 'asts2_t'
    'asti64' = 'asts3_t'
    'astf32' = 'astf2_t'
    'astf64' = 'astf3_t'
    'astvcs' = 'astvcst_t'
    'astvs' = 'astvstr_t'
    'vu8' = 'vu0_t'
    'vu16' = 'vu1_t'
    'vu32' = 'vu2_t'
    'vu64' = 'vu3_t'
    'vi8' = 'vs0_t'
    'vi16' = 'vs1_t'
    'vi32' = 'vs2_t'
    'vi64' = 'vs3_t'
    'vcu8' = 'vcu0_t'
    'vcu16' = 'vcu1_t'
    'vcu32' = 'vcu2_t'
    'vcu64' = 'vcu3_t'
    'vci8' = 'vcs0_t'
    'vci16' = 'vcs1_t'
    'vci32' = 'vcs2_t'
    'vci64' = 'vcs3_t'
    'vf32' = 'vf2_t'
    'vf64' = 'vf3_t'
    'vcf32' = 'vcf2_t'
    'vcf64' = 'vcf3_t'
    'vcvcs' = 'vcvcst_t'
    'vvcs' = 'vvcst_t'
    'vcs' = 'vcst_t'
    'vs' = 'vstr_t'
    'SYSTEM_EVENT_Mouse' = 'EVENT_SYSTEM_Mouse'
}
if(-not @(Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'llc_event_system.h' -ErrorAction SilentlyContinue).Count) {
    $null = $map.Remove('SYSTEM_EVENT_Mouse')
}

$encoding = [System.Text.UTF8Encoding]::new($false)
$names = @($map.Keys | Sort-Object Length -Descending | ForEach-Object { [regex]::Escape($_) })
$retiredErrors = 'OS_(?:ERROR|BUSY|INVALID_PARAMETER|NOT_FOUND|NO_MEMORY|OK)'
$tokenPattern = '(?s)(?<literalLeft>"(?:\\.|[^"\\])*")(?<beforeOp>\s*)(?<comparison>==|!=)(?<afterOp>\s*)(?<comparisonRight>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)|(?<stringInit>\b(?:::llc::|llc::)string\s+[A-Za-z_]\w*\s*=\s*[^;\r\n]*\?[^;\r\n]*;)|(?<connectionAssign>\b[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*\.Connection\s*=\s*[^;\r\n]*\?\s*"(?:\\.|[^"\\])*"\s*:\s*"(?:\\.|[^"\\])*"\s*;)|"(?:\\.|[^"\\])*"|''(?:\\.|[^''\\])*''|/\*.*?\*/|//[^\r\n]*|(?<![A-Za-z0-9_])(?<receiver>[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\.append_string\s*\(|(?<![A-Za-z0-9_])(?<staticView>[A-Za-z_]\w*)\.as\s*<\s*(?:::llc::)?sc_c\s*>\s*\(\s*\)|(?<![A-Za-z0-9_:])digit\s*\(\s*(?<digitArg>[A-Za-z_]\w*)\s*\)|(?<![A-Za-z0-9_])(?:(?:::)?llc::)?' + $retiredErrors + '(?![A-Za-z0-9_])|(?<![A-Za-z0-9_])(?:' + ($names -join '|') + ')(?![A-Za-z0-9_])'
$tokenPattern = '(?m)(?<macroDefinition>^[ \t]*#[ \t]*(?:define|undef)\b(?:[^\r\n]*\\\r?\n)*[^\r\n]*)|' + $tokenPattern
try {
Write-Feedback ('Mode: ' + $(if($Apply) { 'APPLY' } else { 'DRY RUN' }))
Write-Feedback ("Log: $([System.IO.Path]::GetFullPath($LogPath))")
Write-Feedback ("Roots: $($Root.Count)")
Write-Feedback ("COMMAND `"$PSCommandPath`" -Root $($Root -join ', ') $(if($Apply) {'-Apply'} else {''}) $(if($All) {'-All'} else {''}) -LogPath `"$LogPath`"")
$totalFiles = 0
$changedFiles = 0
$changedLines = 0
$skippedFiles = 0
foreach($rootPath in $Root) {
Write-Feedback ("ROOT $rootPath")
$files = Get-ChildItem -LiteralPath $rootPath -Recurse -File |
    Where-Object { $_.Extension -in @('.h', '.cpp', '.hpp') -and $_.FullName -notmatch '[\\/](obj|x64\.[^\\/]+)[\\/]' }
foreach($file in $files) {
    if($file.Name -in @('llc_platform_globals.h', 'llc_typeint.h', 'llc_error.h', 'llc_string_compose.h') -or $file.Name -like 'llc_log*.h') {
        ++$skippedFiles
        if($All) {
            Write-Feedback ("FILE $($file.FullName)")
            Write-Feedback '  STATUS SKIPPED: owning definition header'
        }
        continue
    }
    ++$totalFiles
    $before = [System.IO.File]::ReadAllText($file.FullName)
    $after = if($hasFrameworkModuleHeader) { [regex]::Replace($before, '(?m)^(?<prefix>[ \t]*#include[ \t]+)"llc_runtime_module\.h"', '${prefix}"llc_framework_module.h"') }
             else { [regex]::Replace($before, '(?m)^(?<prefix>[ \t]*#include[ \t]+)"llc_framework_module\.h"', '${prefix}"llc_runtime_module.h"') }
    $after = [regex]::Replace($after, '(?<type>(?:::llc::|llc::)vcst_t)\{(?<literal>"(?:\\.|[^"\\])*")\s*,\s*\(::llc::u2_t\)-1\}', '${type}{${literal}}')
    $after = [regex]::Replace($after, '(?<type>(?:::llc::|llc::)vcst_t)\{(?<expression>[^{}\r\n]*,[^{}\r\n]*\?[^{}\r\n]*),\s*\(::llc::u2_t\)-1\}', '${type}{${expression}}')
    $after = [regex]::Replace($after, '(?<type>(?:::llc::|llc::)vcst_t)\{(?<expression>[^{}\r\n]*\?[^{}\r\n]*:[^{}\r\n]*)\}', [System.Text.RegularExpressions.MatchEvaluator]{ param($match)
        if($match.Groups['expression'].Value.Contains(',')) { return $match.Value }
        return $match.Groups['type'].Value + '{' + $match.Groups['expression'].Value + ', (::llc::u2_t)-1}'
    })
    $staticArrays = @{}
    foreach($declaration in [regex]::Matches($before, '\bastsc_t\s*<[^>\r\n]+>\s*(?<name>[A-Za-z_]\w*)')) { $staticArrays[$declaration.Groups['name'].Value] = $true }
    $aliasDeclarations = [regex]::Matches($after, '\b(?:tydf|typedef|tdcs)\b[^;\r\n]*?\b(?<name>[A-Za-z_]\w*)\s*;|\b(?:using|tplN2uusng|tplTN2usng)\s+(?<name>[A-Za-z_]\w*)\s*=')
    $definedAliases = @{}
    foreach($declaration in $aliasDeclarations) { $definedAliases[$declaration.Groups['name'].Value] = $true }
    $protectedAliasNames = @{}
    foreach($declaration in $aliasDeclarations) {
        $oldName = $declaration.Groups['name'].Value
        if($map.Contains($oldName) -and $definedAliases.ContainsKey([string]$map[$oldName])) { $protectedAliasNames[$declaration.Groups['name'].Index] = $true }
    }
    $after = [regex]::Replace($after, $tokenPattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($match)
        if($protectedAliasNames.ContainsKey($match.Index)) { return $match.Value }
        if($match.Groups['macroDefinition'].Success) { return $match.Value }
        if($match.Groups['literalLeft'].Success) {
            return $match.Groups['comparisonRight'].Value + $match.Groups['beforeOp'].Value + $match.Groups['comparison'].Value + $match.Groups['afterOp'].Value + $match.Groups['literalLeft'].Value
        }
        if($match.Groups['stringInit'].Success) {
            $statement = $match.Value
            $equals = $statement.IndexOf('=')
            $prefix = $statement.Substring(0, $equals + 1)
            $expression = $statement.Substring($equals + 1, $statement.Length - $equals - 2).Trim()
            if($expression -match '\bvcst_t\b') { return $statement }
            return $prefix + ' ::llc::vcst_t{' + $expression + '};'
        }
        if($match.Groups['connectionAssign'].Success) {
            $statement = $match.Value
            $equals = $statement.IndexOf('=')
            $prefix = $statement.Substring(0, $equals + 1)
            $expression = $statement.Substring($equals + 1, $statement.Length - $equals - 2).Trim()
            return $prefix + ' ::llc::vcst_t{' + $expression + '};'
        }
        if($match.Value.StartsWith('"') -or $match.Value.StartsWith("'") -or $match.Value.StartsWith('//') -or $match.Value.StartsWith('/*')) { return $match.Value }
        if($match.Groups['receiver'].Success) { return '::llc::append_string(' + $match.Groups['receiver'].Value + ', ' }
        if($match.Groups['staticView'].Success) {
            $receiver = $match.Groups['staticView'].Value
            if($staticArrays.ContainsKey($receiver)) { return '::llc::vcst_t{' + $receiver + '.Storage}' }
            return $match.Value
        }
        if($match.Groups['digitArg'].Success) { return '::std::isdigit(static_cast<unsigned char>(' + $match.Groups['digitArg'].Value + '))' }
        if($match.Value -match $retiredErrors) { return $(if($match.Value -match 'OS_OK$') { '0' } else { '-1' }) }
        return [string]$map[$match.Value]
    })
    if($before -match '\b(?:llc_necs|llc_necall|gthrow_if|gsthrow_if)\b') {
        $after = Add-ConditionalFailureBraces $after
    }
    # Token replacements can create a vcst_t wrapper; finish it in this same run.
    $after = [regex]::Replace($after, '(?<type>(?:::llc::|llc::)vcst_t)\{(?<expression>[^{}\r\n]*\?[^{}\r\n]*:[^{}\r\n]*)\}', [System.Text.RegularExpressions.MatchEvaluator]{ param($match)
        if($match.Groups['expression'].Value.Contains(',')) { return $match.Value }
        return $match.Groups['type'].Value + '{' + $match.Groups['expression'].Value + ', (::llc::u2_t)-1}'
    })
    if($before -match '\.append_string\s*\(' -and $after -notmatch '#include\s+"llc_string_compose\.h"') {
        $newline = if($after.Contains("`r`n")) { "`r`n" } else { "`n" }
        $after = '#include "llc_string_compose.h"' + $newline + $after
    }
    if($before -match '(?<![A-Za-z0-9_:])digit\s*\(\s*[A-Za-z_]\w*\s*\)' -and $after -notmatch '#include\s*<cctype>') {
        $newline = if($after.Contains("`r`n")) { "`r`n" } else { "`n" }
        $after = '#include <cctype>' + $newline + $after
    }
    if(-not $hasEventDeviceHeader -or $file.Name -in @('llc_event_device.h', 'llc_event.h')) {
        $after = $after.Replace('#include "llc_event_device.h"' + "`r`n", '').Replace('#include "llc_event_device.h"' + "`n", '')
    }
    if($hasEventDeviceHeader -and $file.Name -notin @('llc_event_device.h', 'llc_event.h') -and $before -match '\bSEventCommand\b' -and $after -notmatch '#include\s+"llc_event_device\.h"') {
        $newline = if($after.Contains("`r`n")) { "`r`n" } else { "`n" }
        $after = '#include "llc_event_device.h"' + $newline + $after
    }
    if($after -cne $before) {
        ++$changedFiles
        Write-Feedback ("FILE $($file.FullName)")
        Write-Feedback ("  STATUS " + $(if($Apply) { 'APPLY' } else { 'WOULD CHANGE' }))
        Write-LineChanges $before $after
        if($Apply) {
            [System.IO.File]::WriteAllText($file.FullName, $after, $encoding)
            Write-Feedback '  WRITE OK'
        }
    }
    elseif($All) {
        Write-Feedback ("FILE $($file.FullName)")
        Write-Feedback '  STATUS UNCHANGED'
    }
}
}
Write-Feedback ("SUMMARY mode=$(if($Apply) {'APPLY'} else {'DRY RUN'}) roots=$($Root.Count) scanned=$totalFiles changed=$changedFiles unchanged=$($totalFiles - $changedFiles) skipped=$skippedFiles changed_lines=$changedLines")
}
finally { $logWriter.Dispose() }
