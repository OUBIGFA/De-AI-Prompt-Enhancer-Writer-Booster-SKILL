param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,
    [int]$ColonBudget = 2,
    [bool]$ColonExceptionsQuoteOnly = $true,
    [switch]$SkipTitleLine
)

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$text = Get-Content -LiteralPath $Path -Encoding utf8 -Raw
$lines = Get-Content -LiteralPath $Path -Encoding utf8
$lineCount = $lines.Count
$charCount = $text.Length

# Paragraph analysis
$paragraphs = ($text.Trim() -split "(\r?\n){2,}")  | Where-Object { $_.Trim().Length -gt 0 -and $_ -notmatch "^\r?\n+$" }
$paragraphCount = $paragraphs.Count
$shortParagraphs = @($paragraphs | Where-Object { $_.Trim().Length -lt 100 -and $_.Trim().Length -gt 0 })
$shortParagraphCount = $shortParagraphs.Count

# Average paragraph length
$totalParaChars = 0
foreach ($p in $paragraphs) { $totalParaChars += $p.Trim().Length }
$avgParaLen = if ($paragraphCount -gt 0) { [math]::Round($totalParaChars / $paragraphCount) } else { 0 }

$headingCount = ([regex]::Matches($text, "(?m)^##\s")).Count

function U([string]$escaped) {
    return [regex]::Unescape($escaped)
}

# Core patterns (original)
$patterns = [ordered]@{
    "er_shi" = (U "\u800c\u662f")
    "bu_shi" = (U "\u4e0d\u662f")
    "ni_hui" = (U "\u4f60\u4f1a")
    "ni" = (U "\u4f60")
    "semicolon" = (U "\uff1b")
    "colon" = (U "\uff1a")
    "period" = (U "\u3002")
    "exclamation" = (U "\uff01")
    "dash" = (U "\u2014\u2014")
    "roadmark_terms" = (
        (U "\u66f4\u5173\u952e") + "|" +
        (U "\u66f4\u8981\u547d") + "|" +
        (U "\u6362\u53e5\u8bdd\u8bf4") + "|" +
        (U "\u4e8b\u5b9e\u4e0a") + "|" +
        (U "\u503c\u5f97\u6ce8\u610f") + "|" +
        (U "\u603b\u4e4b") + "|" +
        (U "\u4e0e\u6b64\u540c\u65f6")
    )
    "ai_roadmarks_extra" = (
        (U "\u4e0d\u53ef\u5426\u8ba4") + "|" +
        (U "\u6beb\u65e0\u7591\u95ee") + "|" +
        (U "\u7efc\u4e0a\u6240\u8ff0")
    )
    "metaphor_markers" = (
        (U "\u5982\u540c") + "|" +
        (U "\u4eff\u4f5b") + "|" +
        (U "\u597d\u6bd4") + "|" +
        (U "\u72b9\u5982")
    )
    "double_adj" = (
        (U "\u800c\u53c8")
    )
}

Write-Output "===== Style Lint Report ====="
Write-Output "File: $Path"
Write-Output "Chars: $charCount"
Write-Output "Lines: $lineCount"
Write-Output ""
Write-Output "--- Paragraph Analysis ---"
Write-Output "Paragraphs: $paragraphCount"
Write-Output "Avg paragraph length: $avgParaLen chars"
Write-Output "Short paragraphs (<100 chars): $shortParagraphCount"
Write-Output "H2 headings (##): $headingCount"
Write-Output "Colon budget: $ColonBudget"
Write-Output ""
Write-Output "--- Pattern Counts ---"

foreach ($entry in $patterns.GetEnumerator()) {
    $count = ([regex]::Matches($text, $entry.Value)).Count
    Write-Output ("  {0}: {1}" -f $entry.Key, $count)
}

Write-Output ""
Write-Output "--- Hit Lines (er_shi|ni_hui) ---"
$hits = Select-String -LiteralPath $Path -Pattern ((U "\u800c\u662f") + "|" + (U "\u4f60\u4f1a"))
if ($hits) {
    $hits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
} else {
    Write-Output "  none"
}

Write-Output ""
Write-Output "--- Colon Lines ---"
$colonChar = U "\uff1a"
$quoteChar = U "\u201c"
$colonHits = Select-String -LiteralPath $Path -Pattern $colonChar
if ($SkipTitleLine -and $colonHits) {
    $colonHits = @($colonHits | Where-Object { $_.LineNumber -gt 1 })
}
if ($colonHits) {
    $colonHits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
} else {
    Write-Output "  none"
}

$colonCount = ([regex]::Matches($text, $colonChar)).Count
if ($SkipTitleLine) {
    $firstLine = $lines[0]
    $firstLineColons = ([regex]::Matches($firstLine, $colonChar)).Count
    $colonCount -= $firstLineColons
}
$quoteOnlyPattern = ((U "\u8bf4") + "|" + (U "\u95ee") + "|" + (U "\u7b54") + "|" + (U "\u5199\u9053") + "|" + (U "\u6307\u51fa") + "|" + (U "\u8868\u793a") + "|" + (U "\u5f3a\u8c03")) + "\s*" + $colonChar + "\s*[" + $quoteChar + """']"
$colonViolations = @()

if ($ColonExceptionsQuoteOnly -and $colonHits) {
    foreach ($hit in $colonHits) {
        if ($hit.Line -notmatch $quoteOnlyPattern) {
            $colonViolations += $hit
        }
    }
}

Write-Output ""
if ($colonViolations.Count -gt 0) {
    Write-Output "--- Colon Violations (non-quote usage) ---"
    $colonViolations | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
}

# Exclamation mark lines
Write-Output ""
$exclChar = U "\uff01"
$exclHits = Select-String -LiteralPath $Path -Pattern $exclChar
if ($exclHits) {
    Write-Output "--- Exclamation Mark Lines ---"
    $exclHits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
}

# Dash lines
Write-Output ""
$dashPattern = U "\u2014\u2014"
$dashHits = Select-String -LiteralPath $Path -Pattern $dashPattern
$dashCount = ([regex]::Matches($text, $dashPattern)).Count
if ($dashCount -gt 3) {
    Write-Output "--- Dash Warning (>3 occurrences: $dashCount) ---"
    if ($dashHits) {
        $dashHits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
    }
}

# Metaphor marker lines (rough screen)
Write-Output ""
$metaphorPattern = $patterns["metaphor_markers"]
$metaphorCount = ([regex]::Matches($text, $metaphorPattern)).Count
Write-Output "--- Metaphor Markers (rough screen) ---"
Write-Output "  Count: $metaphorCount"
if ($metaphorCount -gt 0) {
    $metaphorHits = Select-String -LiteralPath $Path -Pattern $metaphorPattern
    $metaphorHits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
}

# Double adjective "A而又B"
Write-Output ""
$doubleAdjPattern = $patterns["double_adj"]
$doubleAdjCount = ([regex]::Matches($text, $doubleAdjPattern)).Count
if ($doubleAdjCount -gt 0) {
    Write-Output "--- Double Adjective Warning (A而又B) ---"
    Write-Output "  Count: $doubleAdjCount"
    $doubleAdjHits = Select-String -LiteralPath $Path -Pattern $doubleAdjPattern
    $doubleAdjHits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
}

# Final result
Write-Output ""
Write-Output "===== Result ====="

$issues = @()

$erShiCount = ([regex]::Matches($text, (U "\u800c\u662f"))).Count
if ($erShiCount -gt 1) { $issues += "er_shi count $erShiCount > 1" }

$niHuiCount = ([regex]::Matches($text, (U "\u4f60\u4f1a"))).Count
if ($niHuiCount -gt 0) { $issues += "ni_hui count $niHuiCount > 0" }

$passBudget = $colonCount -le $ColonBudget
if (-not $passBudget) { $issues += "colon count $colonCount exceeds budget $ColonBudget" }

$passColonUsage = (-not $ColonExceptionsQuoteOnly) -or ($colonViolations.Count -eq 0)
if (-not $passColonUsage) { $issues += "non-quote colon usage detected" }

if ($shortParagraphCount -ge 4) { $issues += "short paragraphs ($shortParagraphCount >= 4)" }

$exclCount = ([regex]::Matches($text, $exclChar)).Count
if ($exclCount -gt 2) { $issues += "exclamation marks $exclCount > 2" }

if ($dashCount -gt 3) { $issues += "dashes $dashCount > 3" }

$roadmarkCount = ([regex]::Matches($text, $patterns["roadmark_terms"])).Count
if ($roadmarkCount -gt 2) { $issues += "roadmark terms $roadmarkCount > 2" }

if ($issues.Count -eq 0) {
    Write-Output "  PASS"
} else {
    Write-Output "  FAIL"
    foreach ($issue in $issues) {
        Write-Output "  - $issue"
    }
}
