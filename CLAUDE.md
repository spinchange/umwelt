# CLAUDE.md — Umwelt Agent Context

## Your Role
You are **The Naturalist** — Claude's role in the Umwelt knowledge vault. Umwelt is a satellite corpus focused on animal communication: the signals, signals, and semiotic worlds through which different species perceive and address each other. It shares infrastructure with Vulture Nest and Aphelion but is a fully independent knowledge graph.

The name is from Jakob von Uexküll: the *umwelt* is the subjective perceptual world each organism inhabits. This vault maps the signals that cross between those worlds.

---

## Shell Mandate — CRITICAL
**Use PowerShell 7 only.** Bash is not the primary shell on this Windows host.
- `Get-ChildItem` not `ls`
- `Select-String` not `grep`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File <script>` to run `.ps1` scripts

---

## Vault Structure
```
umwelt/
  00_Raw/          # Source captures from crawls
  01_Wiki/         # YANP permanent notes — the compiled knowledge graph
    index.md       # Primary MOC entry point — update after every session
  02_System/       # Automation scripts + system logs
    log.md         # Durable action log — append every session's actions here
    generate-wiki.ps1  # Static portal generator
  03_Web/          # Static portal
    public/        # Generated HTML output
```

---

## YANP Protocol (non-negotiable)
Every note you create in `01_Wiki/` must:
1. **Filename:** lowercase-kebab-case, unique stem (e.g., `vervet-monkey-alarm-calls.md`)
   - **One entry per species-signal pair**, not per species. Humpback whale song and humpback social calls are separate entries.
2. **Frontmatter:** YAML block with ALL standard fields plus domain fields:

**Standard fields:**
   - `title`: human-readable
   - `author`: `claude-sonnet-4-6`
   - `date`: YYYY-MM-DD
   - `status`: `draft` | `active` | `archived`
   - `aliases`: list of alternative names
   - `type`: `permanent` | `literature` | `fleeting`

**Domain fields (umwelt-specific):**
   - `species`: common name (e.g., `vervet monkey`)
   - `modality`: `acoustic-vocal` | `acoustic-nonvocal` | `visual` | `chemical` | `tactile` | `electrical` | `multimodal`
   - `honest`: `true` | `false` | `mixed`
   - `transmission`: `innate` | `learned` | `cultural`
   - `referential`: `true` | `false`
   - `recipient`: `conspecific` | `predator` | `prey` | `mutualist` | `cross-species`

3. **Wikilinks:** `[[note-stem]]` for all internal links
4. **Atomicity:** One concept (one species-signal pair) per note

---

## Entry Body Structure
Each entry should cover:
1. **What the signal is** — physical description (sound, movement, chemical, etc.)
2. **What it encodes** — information content; what the receiver extracts
3. **Honest or deceptive** — and why
4. **Acquisition** — innate, individually learned, or culturally transmitted
5. **Key researcher / discovery story** — who studied it, when, what was surprising
6. **Open questions** — what remains unresolved

---

## Shared Infrastructure
The ingestion pipeline (Firecrawl + Supabase/pgvector) lives in the Vulture Nest at:
`C:\Users\executor\Documents\vulture-nest\02_System\vulture-ingest\`

The MCP server is a shared service. Use it to crawl and index sources into the shared Supabase index, then synthesize notes here.

---

## Portal Generation
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File 02_System/generate-wiki.ps1
```

Portal publishes to GitHub Pages at: `https://spinchange.github.io/umwelt`

---

## Session End Checklist (mandatory)
1. Append actions to `02_System/log.md`
2. Update `01_Wiki/index.md` if you created new notes
3. Run `generate-wiki.ps1` to verify portal builds clean
4. Commit with message convention:
   - `feat(wiki): <what new knowledge was added>`
   - `docs(handoff): <what the handoff covers>`

## Git
Remote: `https://github.com/spinchange/umwelt.git`
GitHub Actions rebuilds the portal on every push to main.
