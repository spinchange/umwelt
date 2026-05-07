<#
.SYNOPSIS
    Compiles wiki markdown notes into static HTML pages.
.DESCRIPTION
    Reads all markdown files in 01_Wiki, extracts YAML frontmatter, converts
    markdown to HTML, resolves wikilinks, builds an in-memory link graph for
    the sidebar, and writes HTML files into 03_Web/public using template.html.
.EXAMPLE
    pwsh -NoProfile -ExecutionPolicy Bypass -File 02_System/generate-wiki.ps1
#>

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

try {
    if ($PSVersionTable.PSEdition -ne 'Core') {
        throw "generate-wiki.ps1 requires PowerShell 7 (pwsh)."
    }

    $PSScriptRoot    = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $VaultRoot       = Split-Path -Parent $PSScriptRoot
    $WikiPath        = Join-Path $VaultRoot '01_Wiki'
    $TemplatePath    = Join-Path $VaultRoot '03_Web/template.html'
    $OutputDirectory = Join-Path $VaultRoot '03_Web/public'
    $LlmsTxtPath     = Join-Path $VaultRoot 'llms.txt'
    $LlmsTxtPublic   = Join-Path $OutputDirectory 'llms.txt'
    $SearchIndexPath = Join-Path $OutputDirectory 'search-index.json'
    $PortalBaseUrl   = 'https://spinchange.github.io/umwelt'
    $RepoBaseUrl     = 'https://github.com/spinchange/umwelt'

    function Get-NormalizedContent {
        param([string]$Path)
        return ((Get-Content -Path $Path -Raw) -replace "`0", '') -replace "`r`n", "`n"
    }

    function ConvertTo-HtmlSafe {
        param([object]$Value)
        return [System.Net.WebUtility]::HtmlEncode($(if ($null -eq $Value) { '' } else { [string]$Value }))
    }

    function Get-HtmlFileName {
        param([string]$NoteName)
        return ([uri]::EscapeDataString($NoteName) -replace '%2F', '/') + '.html'
    }

    function Get-PortalUrl {
        param([string]$NoteName)
        return "$PortalBaseUrl/$(Get-HtmlFileName -NoteName $NoteName)"
    }

    function New-WikiAnchor {
        param([string]$Target, [string]$Label, [string]$CssClass = 'wikilink')
        $href  = ConvertTo-HtmlSafe (Get-HtmlFileName -NoteName $Target)
        $label = ConvertTo-HtmlSafe $Label
        $class = ConvertTo-HtmlSafe $CssClass
        return "<a href=""$href"" class=""$class"">$label</a>"
    }

    function Parse-FrontmatterValue {
        param([string]$RawValue)
        $trimmed = $RawValue.Trim()
        if ($trimmed -match '^\[(.*)\]$') {
            $inner = $Matches[1].Trim()
            if ([string]::IsNullOrWhiteSpace($inner)) { return @() }
            return @($inner -split ',' | ForEach-Object { $_.Trim().Trim("'`"") } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        }
        return $trimmed.Trim("'`"")
    }

    function Split-Frontmatter {
        param([string]$Content)
        $match = [regex]::Match($Content, '^(?s)---\n(.*?)\n---\n?')
        $frontmatter = [ordered]@{}
        $body = $Content
        if ($match.Success) {
            $frontmatterText = $match.Groups[1].Value
            $body = $Content.Substring($match.Length).TrimStart("`n")
            foreach ($line in ($frontmatterText -split "`n")) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split ':\s*', 2
                if ($parts.Count -ne 2) { continue }
                $frontmatter[$parts[0].Trim()] = Parse-FrontmatterValue -RawValue $parts[1]
            }
        }
        return [PSCustomObject]@{ Frontmatter = $frontmatter; Body = $body }
    }

    function Convert-InlineMarkdown {
        param([string]$Text)
        $encoded = ConvertTo-HtmlSafe $Text
        $encoded = [regex]::Replace($encoded, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
        $encoded = [regex]::Replace($encoded, '\[\[([^\]|]+)\|([^\]]+)\]\]', { param($m) New-WikiAnchor -Target $m.Groups[1].Value.Trim() -Label $m.Groups[2].Value.Trim() })
        $encoded = [regex]::Replace($encoded, '\[\[([^\]]+)\]\]', { param($m) $t = $m.Groups[1].Value.Trim(); New-WikiAnchor -Target $t -Label $t })
        $encoded = [regex]::Replace($encoded, '\*\*(.+?)\*\*', '<strong>$1</strong>')
        $encoded = [regex]::Replace($encoded, '(?<!`)`([^`]+)`(?!`)', '<code>$1</code>')
        return $encoded
    }

    function Get-ListItemData {
        param([string]$Line)
        if ($Line -match '^(\s*)([-*])\s+(.+)$') { return [PSCustomObject]@{ Type = 'ul'; Level = [math]::Floor($Matches[1].Replace("`t",'    ').Length / 2); Content = $Matches[3] } }
        if ($Line -match '^(\s*)(\d+)\.\s+(.+)$') { return [PSCustomObject]@{ Type = 'ol'; Level = [math]::Floor($Matches[1].Replace("`t",'    ').Length / 2); Content = $Matches[3] } }
        return $null
    }

    function Close-OpenLists {
        param($Html, $Stack, $TargetDepth = 0)
        while ($Stack.Count -gt $TargetDepth) { $list = $Stack[$Stack.Count - 1]; $Html.Add('</li>'); $Html.Add("</$($list.Type)>"); $Stack.RemoveAt($Stack.Count - 1) }
    }

    function Convert-MarkdownToHtml {
        param([string]$Markdown)
        $lines = $Markdown -split "`n"
        $html = New-Object System.Collections.Generic.List[string]
        $listStack = New-Object System.Collections.Generic.List[object]
        $paragraphLines = New-Object System.Collections.Generic.List[string]
        $tableLines = New-Object System.Collections.Generic.List[string]
        $codeFenceOpen = $false
        $codeLines = New-Object System.Collections.Generic.List[string]

        function Flush-Paragraph {
            if ($paragraphLines.Count -eq 0) { return }
            $joined = ($paragraphLines -join ' ').Trim()
            if ($joined) { $html.Add("<p>$(Convert-InlineMarkdown -Text $joined)</p>") }
            $paragraphLines.Clear()
        }
        function Flush-Table {
            if ($tableLines.Count -eq 0) { return }
            $rows = @($tableLines | ForEach-Object { $_ })
            $tableLines.Clear()
            $splitRow = [scriptblock]{
                param([string]$Row)
                $parts = @($Row -split '\|')
                if ($parts.Count -gt 0 -and [string]::IsNullOrWhiteSpace($parts[0])) { $parts = $parts[1..($parts.Count - 1)] }
                if ($parts.Count -gt 0 -and [string]::IsNullOrWhiteSpace($parts[-1])) { $parts = $parts[0..($parts.Count - 2)] }
                return @($parts | ForEach-Object { $_.Trim() })
            }
            $hasSeparator = $false
            if ($rows.Count -ge 2) {
                $sepCells = @($rows[1] -split '\|' | Where-Object { $_.Trim() -ne '' })
                $hasSeparator = $sepCells.Count -gt 0 -and ($sepCells | Where-Object { $_.Trim() -notmatch '^:?-+:?$' }).Count -eq 0
            }
            $html.Add('<table>')
            if ($hasSeparator) {
                $headerCells = & $splitRow $rows[0]
                $html.Add('<thead><tr>')
                foreach ($cell in $headerCells) { $html.Add("<th>$(Convert-InlineMarkdown -Text $cell)</th>") }
                $html.Add('</tr></thead><tbody>')
                for ($r = 2; $r -lt $rows.Count; $r++) {
                    $cells = & $splitRow $rows[$r]
                    $html.Add('<tr>')
                    foreach ($cell in $cells) { $html.Add("<td>$(Convert-InlineMarkdown -Text $cell)</td>") }
                    $html.Add('</tr>')
                }
                $html.Add('</tbody>')
            } else {
                $html.Add('<tbody>')
                foreach ($row in $rows) {
                    $cells = & $splitRow $row
                    $html.Add('<tr>')
                    foreach ($cell in $cells) { $html.Add("<td>$(Convert-InlineMarkdown -Text $cell)</td>") }
                    $html.Add('</tr>')
                }
                $html.Add('</tbody>')
            }
            $html.Add('</table>')
        }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if ($line -match '^\s*-\s*\*\*(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2})\*\*:\s*(.+)$') {
                Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0
                $html.Add("<div class=""log-entry""><span class=""log-time"">$($Matches[1])</span><span class=""log-content"">$(Convert-InlineMarkdown -Text $Matches[2].Trim())</span></div>")
                continue
            }
            if ($codeFenceOpen) {
                if ($line -match '^```') { $codeFenceOpen = $false; $html.Add("<pre><code>$(ConvertTo-HtmlSafe ($codeLines -join "`n"))</code></pre>"); $codeLines.Clear() }
                else { $codeLines.Add($line) }
                continue
            }
            if ($line -match '^```') { Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0; $codeFenceOpen = $true; $codeLines.Clear(); continue }
            if ($line -match '^\s*\|') { Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0; $tableLines.Add($line); continue }
            if ($tableLines.Count -gt 0) { Flush-Table }
            if ([string]::IsNullOrWhiteSpace($line)) { Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0; continue }
            if ($line -match '^(#{1,6})\s+(.+)$') { Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0; $html.Add("<h$($Matches[1].Length)>$(Convert-InlineMarkdown -Text $Matches[2].Trim())</h$($Matches[1].Length)>"); continue }
            $listItem = Get-ListItemData -Line $line
            if ($listItem) {
                Flush-Paragraph
                while ($listStack.Count -gt ($listItem.Level + 1)) { $current = $listStack[$listStack.Count - 1]; $html.Add('</li>'); $html.Add("</$($current.Type)>"); $listStack.RemoveAt($listStack.Count - 1) }
                if ($listStack.Count -eq ($listItem.Level + 1)) { $html.Add('</li>'); if ($listStack[$listStack.Count - 1].Type -ne $listItem.Type) { $current = $listStack[$listStack.Count - 1]; $html.Add("</$($current.Type)>"); $listStack.RemoveAt($listStack.Count - 1) } }
                while ($listStack.Count -lt $listItem.Level) { $html.Add('<ul>'); $listStack.Add([PSCustomObject]@{ Type = 'ul' }); $html.Add('<li>') }
                if ($listStack.Count -eq $listItem.Level) { $html.Add("<$($listItem.Type)>"); $listStack.Add([PSCustomObject]@{ Type = $listItem.Type }) }
                $html.Add("<li>$(Convert-InlineMarkdown -Text $listItem.Content.Trim())")
                continue
            }
            if ($line -match '^\s*---\s*$') { Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0; $html.Add('<hr>'); continue }
            $paragraphLines.Add($line.Trim())
        }
        Flush-Paragraph; Close-OpenLists -Html $html -Stack $listStack -TargetDepth 0
        if ($tableLines.Count -gt 0) { Flush-Table }
        if ($codeFenceOpen) { $html.Add("<pre><code>$(ConvertTo-HtmlSafe ($codeLines -join "`n"))</code></pre>") }
        return ($html -join [Environment]::NewLine)
    }

    function Convert-MarkdownToSearchText {
        param([string]$Markdown)
        $text = $Markdown
        $text = [regex]::Replace($text, '(?s)```.*?```', ' ')
        $text = [regex]::Replace($text, '\[\[([^\]|]+)\|([^\]]+)\]\]', '$2')
        $text = [regex]::Replace($text, '\[\[([^\]]+)\]\]', '$1')
        $text = [regex]::Replace($text, '\[([^\]]+)\]\(([^)]+)\)', '$1')
        $text = [regex]::Replace($text, '(?m)^\s{0,3}#{1,6}\s*', '')
        $text = [regex]::Replace($text, '(?m)^\s*[-*+]\s+', '')
        $text = [regex]::Replace($text, '(?m)^\s*\d+\.\s+', '')
        $text = $text -replace '\*\*', '' -replace '`', '' -replace '\|', ' '
        $text = [System.Net.WebUtility]::HtmlDecode($text)
        return ([regex]::Replace($text, '\s+', ' ')).Trim()
    }

    function Build-LinkGraph {
        param([System.IO.FileInfo[]]$Files)
        $graph = @{}
        foreach ($file in $Files) {
            $noteName = $file.BaseName
            $content = Get-NormalizedContent -Path $file.FullName
            $parts = Split-Frontmatter -Content $content
            $links = [regex]::Matches($parts.Body, '\[\[([^\]|]+)(?:\|[^\]]+)?\]\]') |
                     ForEach-Object { $_.Groups[1].Value.Trim() } |
                     Where-Object { $_ -ne $noteName } |
                     Select-Object -Unique
            $graph[$noteName] = @($links)
        }
        return $graph
    }

    function Get-GraphNeighbors {
        param([string]$NoteName)
        $outgoing = @($Script:LinkGraph[$NoteName] ?? @())
        $incoming = @($Script:LinkGraph.Keys | Where-Object { $Script:LinkGraph[$_] -contains $NoteName })
        return [PSCustomObject]@{ Outgoing = $outgoing; Incoming = $incoming }
    }

    function Convert-GraphNeighborsToHtml {
        param([string[]]$Incoming, [string[]]$Outgoing)
        $sections = New-Object System.Collections.Generic.List[string]
        if ($Incoming.Count -gt 0) {
            $sections.Add('<span class="graph-section-label">Links To This Note</span>')
            $sections.Add('<ul>')
            foreach ($note in $Incoming) { $sections.Add("<li>$(New-WikiAnchor -Target $note -Label $note -CssClass '')</li>") }
            $sections.Add('</ul>')
        }
        if ($Outgoing.Count -gt 0) {
            $sections.Add('<span class="graph-section-label">Links From This Note</span>')
            $sections.Add('<ul>')
            foreach ($note in $Outgoing) { $sections.Add("<li>$(New-WikiAnchor -Target $note -Label $note -CssClass '')</li>") }
            $sections.Add('</ul>')
        }
        if ($sections.Count -eq 0) { return '<div class="graph-empty">No graph neighbors recorded.</div>' }
        return ($sections -join [Environment]::NewLine)
    }

    function Convert-FrontmatterToHtml {
        param([hashtable]$Frontmatter)
        if (-not $Frontmatter -or $Frontmatter.Count -eq 0) { return '<span class="fm-field"><span class="fm-key">meta</span><span class="fm-val">none</span></span>' }
        $items = foreach ($entry in $Frontmatter.GetEnumerator()) {
            $rawValue = if ($entry.Value -is [System.Collections.IEnumerable] -and $entry.Value -isnot [string]) { ($entry.Value | ForEach-Object { [string]$_ }) -join ', ' } else { [string]$entry.Value }
            $statusClass = if ($entry.Key -eq 'status') { " status-$($rawValue.ToLowerInvariant())" } else { '' }
            "<span class=""fm-field""><span class=""fm-key"">$(ConvertTo-HtmlSafe $entry.Key)</span><span class=""fm-val$statusClass"">$(ConvertTo-HtmlSafe $rawValue)</span></span>"
        }
        return ($items -join [Environment]::NewLine)
    }

    function New-SearchIndexEntry {
        param([string]$NoteName, [string]$Title, [hashtable]$Frontmatter, [string]$Body)
        $aliases = @()
        if ($Frontmatter.Contains('aliases')) {
            $raw = $Frontmatter['aliases']
            if ($raw -is [System.Array]) { $aliases = @($raw | ForEach-Object { [string]$_ }) }
            elseif ($null -ne $raw -and -not [string]::IsNullOrWhiteSpace([string]$raw)) { $aliases = @([string]$raw) }
        }
        $bodyText = Convert-MarkdownToSearchText -Markdown $Body
        $excerpt = if ($bodyText.Length -gt 220) { $bodyText.Substring(0, 220) + '…' } else { $bodyText }
        $searchParts = @($Title, $NoteName, ($aliases -join ' '), $excerpt, $bodyText) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        return [PSCustomObject]@{
            note    = $NoteName
            title   = $Title
            url     = Get-HtmlFileName -NoteName $NoteName
            aliases = $aliases
            type    = if ($Frontmatter.Contains('type')) { [string]$Frontmatter['type'] } else { '' }
            status  = if ($Frontmatter.Contains('status')) { [string]$Frontmatter['status'] } else { '' }
            excerpt = $excerpt
            search  = (($searchParts -join ' ') -replace '\s+', ' ').Trim().ToLowerInvariant()
        }
    }

    function New-LlmsTxtContent {
        param([System.IO.FileInfo[]]$WikiFiles)
        $generatedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add('# umwelt')
        $lines.Add('')
        $lines.Add('> A YANP-compliant knowledge vault for animal communication, biosemiotics, and the study of signals crossing between perceptual worlds.')
        $lines.Add('')
        $lines.Add("Generated: $generatedAt")
        $lines.Add("Repository: $RepoBaseUrl")
        $lines.Add("Portal: $PortalBaseUrl/index.html")
        $lines.Add("Machine-readable file: $PortalBaseUrl/llms.txt")
        $lines.Add('')
        $lines.Add('## What This Is')
        $lines.Add('')
        $lines.Add('Umwelt is a satellite knowledge corpus named after Jakob von Uexküll''s concept of the subjective perceptual world each organism inhabits. It compiles animal communication research into YANP permanent notes, one entry per species-signal pair, with structured frontmatter for cross-modal queries. Shares ingestion infrastructure with the Vulture Nest and Aphelion vaults.')
        $lines.Add('')
        $lines.Add('## Current Surface')
        $lines.Add('')
        $lines.Add("- Wiki notes: $($WikiFiles.Count)")
        $lines.Add('')
        $lines.Add('## Start Here')
        $lines.Add('')
        $lines.Add("- [Index]($(Get-PortalUrl -NoteName 'index')): Primary navigation hub.")
        $lines.Add("- [Log]($(Get-PortalUrl -NoteName 'log')): Session history.")
        return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
    }

    if (-not (Test-Path $TemplatePath)) { throw "Template not found: $TemplatePath" }
    if (-not (Test-Path $OutputDirectory)) { New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }

    $template = Get-NormalizedContent -Path $TemplatePath
    $wikiFiles = @(Get-ChildItem -Path $WikiPath -File -Filter '*.md' | Sort-Object Name)
    $systemMarkdownFiles = @(Get-ChildItem -Path $PSScriptRoot -File -Filter '*.md' | Sort-Object Name)
    $allFiles = @($wikiFiles) + @($systemMarkdownFiles)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $results = New-Object System.Collections.Generic.List[object]
    $searchEntries = New-Object System.Collections.Generic.List[object]

    $Script:LinkGraph = Build-LinkGraph -Files $allFiles

    foreach ($file in $allFiles) {
        $noteName = $file.BaseName
        $content = Get-NormalizedContent -Path $file.FullName
        $parts = Split-Frontmatter -Content $content
        $title = if ($parts.Frontmatter.Contains('title')) { [string]$parts.Frontmatter['title'] } else { $noteName }
        $searchEntries.Add((New-SearchIndexEntry -NoteName $noteName -Title $title -Frontmatter $parts.Frontmatter -Body $parts.Body))

        $outputPath = Join-Path $OutputDirectory (Get-HtmlFileName -NoteName $noteName)
        if (-not $Force -and (Test-Path $outputPath)) {
            if ($file.LastWriteTime -le (Get-Item $outputPath).LastWriteTime) { continue }
        }
        Write-Host "Compiling $noteName..." -ForegroundColor Gray
        $bodyHtml = Convert-MarkdownToHtml -Markdown $parts.Body
        $frontmatterHtml = Convert-FrontmatterToHtml -Frontmatter $parts.Frontmatter
        $neighbors = Get-GraphNeighbors -NoteName $noteName
        $graphHtml = Convert-GraphNeighborsToHtml -Incoming $neighbors.Incoming -Outgoing $neighbors.Outgoing
        $pageHtml = $template.Replace('{{TITLE}}', (ConvertTo-HtmlSafe $title)).Replace('{{CONTENT}}', $bodyHtml).Replace('{{FRONTMATTER}}', $frontmatterHtml).Replace('{{GRAPH_NEIGHBORS}}', $graphHtml)
        [System.IO.File]::WriteAllText($outputPath, $pageHtml, $utf8NoBom)
        $results.Add([PSCustomObject]@{ Note = $noteName; Title = $title; OutputPath = $outputPath })
    }

    $llmsTxt = New-LlmsTxtContent -WikiFiles $wikiFiles
    [System.IO.File]::WriteAllText($LlmsTxtPath, $llmsTxt, $utf8NoBom)
    [System.IO.File]::WriteAllText($LlmsTxtPublic, $llmsTxt, $utf8NoBom)
    $searchIndexJson = [string](ConvertTo-Json -InputObject $searchEntries.ToArray() -Depth 6 -Compress)
    Set-Content -LiteralPath $SearchIndexPath -Value $searchIndexJson -Encoding utf8

    if ($results.Count -gt 0) { Write-Host "Compiled $($results.Count) pages into $OutputDirectory" -ForegroundColor Green }
    else { Write-Host "No HTML changes detected. Portal is up to date." -ForegroundColor Cyan }
    Write-Host "Refreshed llms.txt and search index." -ForegroundColor Green
    return $results
} catch { Write-Error $_; exit 1 }
