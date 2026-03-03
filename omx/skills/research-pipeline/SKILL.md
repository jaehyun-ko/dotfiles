---
name: research-pipeline
description: Pipeline preset for running agentic-researcher (history->ideas->math->experiments->paper) with OMX state tracking
---

# Research Pipeline Skill

`$research-pipeline` is a **thin OMX wrapper** around the canonical **agentic-researcher**
workflow. It exists to:

- provide a convenient “run this research loop” entrypoint, and
- map progress to OMX state phases (HUD-friendly).

## Single Source of Truth (important)

The actual research workflow (gates, artifacts, paper policy, recommended flags) lives in:

- `~/.codex/skills/agentic-researcher/SKILL.md`

This wrapper intentionally **does not redefine** the research procedure. If something in the
workflow changes, update the **agentic-researcher skill/repo**, not this file.

## Preconditions

- `agentic-researcher` skill is installed at `~/.codex/skills/agentic-researcher/` (run `codex-sync` if missing).
- `uv` is available.
- `AGENTIC_RESEARCHER_REPO` points to the repo (default: `~/projects/agentic-researcher`).

## Input Contract (minimum)

Required:
- `research_question`
- `required_keywords[]` (>= 1)

Optional:
- `conference_deadline` (`YYYY-MM-DD`)
- `output_dir` (default: `<cwd>/.omx/agentic-researcher/<timestamp>`)

## OMX Phase Mapping (HUD only)

These phases are only for **OMX progress tracking**. For the authoritative gates/details,
follow `~/.codex/skills/agentic-researcher/SKILL.md`.

- `stage:scope`  → scope lock (H0)
- `stage:history` → research-history gate (H0~H5)
- `stage:ideas`  → idea evidence gate (I0~I3)
- `stage:math`   → math checklist
- `stage:toy`    → toy experiments
- `stage:full`   → full experiments
- `stage:docs`   → update cycle docs/rollup
- `stage:paper`  → paper / paper-audit (only when triggered by readiness)

## Run (example)

For the current recommended flags and modes, see:

- `~/.codex/skills/agentic-researcher/SKILL.md`

Minimal example from `$AGENTIC_RESEARCHER_REPO`:

```bash
bash scripts/bootstrap_uv_env.sh

uv run python scripts/researcher.py \
  --mode loop-multi \
  --question "<research_question>" \
  --keywords <k1> <k2> ... \
  --conference-deadline "<YYYY-MM-DD>" \
  --output-dir "<output_dir>"
```

## State Management (OMX)

- **On start**:
  - `state_write({mode: "pipeline", active: true, current_phase: "stage:scope"})`
- **On stage transition**:
  - `state_write({mode: "pipeline", current_phase: "stage:<name>"})`
- **On completion**:
  - `state_write({mode: "pipeline", active: false, current_phase: "complete"})`
