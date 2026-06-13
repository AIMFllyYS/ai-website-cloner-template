# 1:1 Frontend Website Replication — Claude Code Skill

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![For Learning Only](https://img.shields.io/badge/Use-Learning%20%26%20Research%20Only-orange.svg)](#legal-notice)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Skill-blueviolet)](https://claude.ai/code)

> **⚠️ For personal learning, technical research, and offline archiving only.**
> Public redeployment, commercial use, or claiming original authorship requires authorization from the rights holder of the target site.

A two-stage frontend website replication skill for [Claude Code](https://claude.ai/code). Stage 1 downloads the compiled production output as an interactive offline mirror. Stage 2 (opt-in, compiled sites only) uses AI to rebuild the site into clean, editable modern source code.

---

## Two-Stage Architecture

```
Stage 1 · Interactive Mirror (all sites, default)
  Fingerprint → Select playbook → Download compiled output → Local server → Verify
  Output: <project>-mirror/  (T0 asset archive + T1 interactive mirror)
        │
        ▼  ★ Handoff gate (mandatory): honest disclosure + site-type routing
   ┌─ Non-compiled site (hand-written static) → "Mirror ≈ source, no Stage 2 needed"
   └─ Compiled site (SPA / WebGL / SSR / bundled) → Offer Stage 2
        │ (user confirms)
        ▼
Stage 2 · AI Equivalent Rebuild (compiled sites only, opt-in)
  Set up 3-folder workspace → Clone engine → Run /clone-website → Verify
  Output: <project>-clone/  (T2-AI equivalent source, Next.js / React / TS)
```

### Honesty Principle

Stage 2 produces an **AI equivalent rebuild on a modern stack — not the target site's original pre-bundle source code.** Compiled/minified output is irreversible. The rebuild aligns visually and interactively with the original; it cannot recover the original modules, shaders, or 3D assets. All Stage 2 outputs must be labeled *"AI equivalent rebuild, not original source."*

---

## Repository Structure

```
skills/
  replicating-frontend-websites/   # ★ Main skill — Stage 1 routing + Stage 2 handoff
  │   SKILL.md                     #   Router: decision tree, iron laws, phase skeleton
  │   references/
  │   │   fingerprinting.md        #   Phase 0: site fingerprinting
  │   │   playbook-static.md       #   Playbook A: pure static / SSG
  │   │   playbook-spa.md          #   Playbook B: DOM SPA / SSR
  │   │   playbook-webgl.md        #   Playbook C: WebGL / Canvas
  │   │   playbook-hybrid.md       #   Playbook D: backend-API sites (additive)
  │   │   playbook-reconstruction.md # ★ Playbook S2: Stage 2 AI rebuild
  │   │   verification.md          #   Honest tier definitions + acceptance gates
  │   │   risks-degradation.md     #   Risk table G1-G19 + degradation matrix
  │   └── scripts/
  │       ├── fingerprint.sh       #   Site fingerprinting script
  │       ├── lib.sh               #   Download helpers (dl / real_asset / probe_seq)
  │       ├── capture.js           #   Playwright HAR capture
  │       ├── har2urls.sh          #   HAR → asset URL list
  │       └── serve.js             #   Local server (MIME + COOP/COEP headers)
  └── clone-website/               # Stage 2 engine skill (used inside <project>-clone/)
      └── SKILL.md

src/                               # Next.js 16 scaffold — the Stage 2 engine project
docs/                              # Research output templates
scripts/                           # Asset download utilities
```

---

## Installation

### Download the Skill Pack (Recommended)

Download **`replicating-frontend-websites.zip`** from the [Releases page](../../releases) and extract it to your Claude Code skills directory:

**Windows (PowerShell):**
```powershell
# User-global — available in all projects
Expand-Archive replicating-frontend-websites.zip "$env:USERPROFILE\.claude\skills\"

# Project-local — available only in current project
Expand-Archive replicating-frontend-websites.zip ".\.claude\skills\"
```

**macOS / Linux:**
```bash
# User-global
unzip replicating-frontend-websites.zip -d ~/.claude/skills/

# Project-local
unzip replicating-frontend-websites.zip -d ./.claude/skills/
```

### Clone This Repository

```bash
git clone https://github.com/AIMFllyYS/ai-website-cloner-template
```

Then copy the skill manually:

```bash
# macOS / Linux
cp -r ai-website-cloner-template/skills/replicating-frontend-websites ~/.claude/skills/

# Windows (PowerShell)
Copy-Item -Recurse ai-website-cloner-template\skills\replicating-frontend-websites "$env:USERPROFILE\.claude\skills\"
```

---

## Requirements

| Feature | Requirement |
|---------|-------------|
| Stage 1 (mirror) | Claude Code, Bash, Node.js (for `serve.js`) |
| Stage 2 (rebuild) | Node.js >= 24, `claude --chrome` (browser MCP) |

---

## Usage

Once the skill is installed, open any Claude Code session and say:

```
# Stage 1 — interactive mirror
1:1 clone this website: https://example.com

# Stage 2 — AI equivalent source rebuild (compiled sites only)
Clone https://example.com and rebuild editable source code
```

The skill activates automatically and walks through:
compliance disclosure → open-source check → fingerprinting → playbook selection → Stage 1 download → acceptance verification → (compiled sites) Stage 2 offer.

### Stage 2 Workspace Layout

```
<workspace>/
├── <project>-mirror/           # Stage 1 output (already exists)
├── ai-website-cloner-template/ # Engine: keep pristine as reference
└── <project>-clone/            # Stage 2 output: copy engine here, run /clone-website
```

To enable the `/clone-website` engine skill inside `<project>-clone/`:

```bash
# Copy engine skill into the project
cp -r ai-website-cloner-template <project>-clone
cd <project>-clone
mkdir -p .claude/skills
cp -r skills/clone-website .claude/skills/
npm install

# Start Claude Code with browser access
claude --chrome
# Then inside the session:
# /clone-website https://example.com
```

---

## Verified Test Cases

| Site | Type | Result |
|------|------|--------|
| `shuchenglin-handbook.pages.dev` | Pure static / SSG | Stage 1 T0+T1, correctly routes "no Stage 2 needed" |
| `www.igloo.inc` | WebGL SPA (Vite + Three.js) | Stage 1 T0+T1 complete; Stage 2 workspace ready, requires `claude --chrome` |

---

## Credits

**Stage 2 engine** (`skills/clone-website/` + `src/` Next.js scaffold):
Derived from [ai-website-cloner-template](https://github.com/JCodesMore/ai-website-cloner-template) by [JCodesMore](https://github.com/JCodesMore), released under the MIT License © 2025 JCodesMore. This fork repurposes the engine as the Stage-2 component of the `replicating-frontend-websites` skill. The original MIT attribution is preserved in [NOTICE](NOTICE).

**Stage 1 skill** (`skills/replicating-frontend-websites/`):
Designed and validated on real-world sites including a Three.js/WebGL experience site (igloo.inc) and a Cloudflare Pages static site.

---

## License

This project is licensed under the **Apache License 2.0** — see [LICENSE](LICENSE).

The `skills/clone-website/` skill and `src/` Next.js scaffold are derived from work by JCodesMore (MIT License © 2025) — see [NOTICE](NOTICE).

---

## Legal Notice

This tool is intended **strictly for personal learning, technical research, and offline archiving**.

- Target sites' brand identity, design language, fonts, images, 3D assets, audio, and source code may be protected by copyright, trademark, and related laws.
- **Mirroring a site does not transfer any rights.** Public redeployment, commercial use, distribution, or claiming original authorship requires explicit authorization from the rights holder.
- Web scraping should respect `robots.txt` conventions, rate limits, and server load — do not burden the source server.
- Stage 2 AI equivalent rebuild does **not** eliminate the target site's content and design copyright. Re-publishing a rebuilt version still requires rights-holder authorization.
- The authors of this skill assume no liability for misuse.

By using this skill, you agree to use it solely for lawful, non-commercial, personal purposes.
