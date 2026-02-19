param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,
    [int]$ColonBudget = 2,
    [bool]$ColonExceptionsQuoteOnly = $true
)

if (-not (Test-Path -LiteralPath $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$text = Get-Content -LiteralPath $Path -Encoding utf8 -Raw
$lines = Get-Content -LiteralPath $Path -Encoding utf8
$lineCount = $lines.Count
$charCount = $text.Length
$paragraphCount = ([regex]::Matches($text.Trim(), "(\r?\n){2,}")).Count + 1
$headingCount = ([regex]::Matches($text, "(?m)^##\s")).Count

function U([string]$escaped) {
    return [regex]::Unescape($escaped)
}

$patterns = [ordered]@{
    "er_shi" = (U "\u800c\u662f")
    "bu_shi" = (U "\u4e0d\u662f")
    "ni_hui" = (U "\u4f60\u4f1a")
    "ni" = (U "\u4f60")
    "semicolon" = (U "\uff1b")
    "colon" = (U "\uff1a")
    "period" = (U "\u3002")
    "roadmark_terms" = (
        (U "\u66f4\u5173\u952e") + "|" +
        (U "\u66f4\u8981\u547d") + "|" +
        (U "\u6362\u53e5\u8bdd\u8bf4") + "|" +
        (U "\u4e8b\u5b9e\u4e0a") + "|" +
        (U "\u503c\u5f97\u6ce8\u610f") + "|" +
        (U "\u603b\u4e4b") + "|" +
        (U "\u4e0e\u6b64\u540c\u65f6")
    )
}

Write-Output "File: $Path"
Write-Output "Chars: $charCount"
Write-Output "Lines: $lineCount"
Write-Output "Paragraphs: $paragraphCount"
Write-Output "H2 headings (##): $headingCount"
Write-Output "Colon budget: $ColonBudget"
Write-Output "Colon quote-only exceptions: $ColonExceptionsQuoteOnly"
Write-Output ""
Write-Output "Counts:"

foreach ($entry in $patterns.GetEnumerator()) {
    $count = ([regex]::Matches($text, $entry.Value)).Count
    Write-Output ("  {0}: {1}" -f $entry.Key, $count)
}

Write-Output ""
Write-Output "Hit lines (er_shi|ni_hui):"
$hits = Select-String -LiteralPath $Path -Pattern ((U "\u800c\u662f") + "|" + (U "\u4f60\u4f1a"))
if ($hits) {
    $hits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
} else {
    Write-Output "  none"
}

Write-Output ""
Write-Output "Colon lines:"
$colonChar = U "\uff1a"
$quoteChar = U "\u201c"
$colonHits = Select-String -LiteralPath $Path -Pattern $colonChar
if ($colonHits) {
    $colonHits | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
} else {
    Write-Output "  none"
}

$colonCount = ([regex]::Matches($text, $colonChar)).Count
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
    Write-Output "Colon violation lines (non-quote usage):"
    $colonViolations | ForEach-Object { Write-Output ("  L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }
}

$passBudget = $colonCount -le $ColonBudget
$passColonUsage = (-not $ColonExceptionsQuoteOnly) -or ($colonViolations.Count -eq 0)

Write-Output ""
Write-Output "Result:"
if ($passBudget -and $passColonUsage) {
    Write-Output "  PASS"
} else {
    Write-Output "  FAIL"
    if (-not $passBudget) {
        Write-Output ("  reason: colon count {0} exceeds budget {1}" -f $colonCount, $ColonBudget)
    }
    if (-not $passColonUsage) {
        Write-Output "  reason: non-quote colon usage detected"
    }
}
