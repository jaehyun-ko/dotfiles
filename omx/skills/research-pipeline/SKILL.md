---
name: research-pipeline
description: Pipeline preset for running agentic-researcher (history->ideas->math->experiments->paper) with OMX state tracking
---

# Research Pipeline Skill

`$research-pipeline` is an OMX workflow preset that runs the **agentic-researcher** loop
while tracking progress in pipeline-like stages (via `omx_state`).

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

## Pipeline Preset: `agentic-researcher`

Stages (do not skip gates):

1) `stage:scope`
   - Lock scope (in/out), timeframe, venue policy, and keywords.

2) `stage:history`
   - Enforce Research-History Gate `H0~H5` (timeline, lineage, negative results, coverage audit, pub-status normalization).

3) `stage:ideas`
   - Enforce Idea Evidence Gate `I0~I3` (per-idea support minimum, claim-evidence map, contradiction check).

4) `stage:math`
   - Run math validation checklist and record `math_validation.json`.

5) `stage:toy`
   - Run toy experiments + gate; record `toy_result.json`.

6) `stage:full`
   - Run full experiments + retry policy; record `full_result.json`.

7) `stage:docs`
   - Update per-cycle docs + rollup summary.

8) `stage:paper` (only when readiness triggered)
   - Run paper pipeline (`paper` / `paper-audit`) per skill policy.

## Canonical Run Command

From `$AGENTIC_RESEARCHER_REPO`:

```bash
bash scripts/bootstrap_uv_env.sh

uv run python scripts/researcher.py \
  --mode loop-multi \
  --question "<research_question>" \
  --keywords <k1> <k2> ... \
  --conference-deadline <YYYY-MM-DD> \
  --max-agent-threads auto \
  --multi-failure-policy fail_fast \
  --agent-profile default \
  --output-dir "<output_dir>"
```

## State Management (OMX)

- **On start**:
  - `state_write({mode: "pipeline", active: true, current_phase: "stage:scope"})`
- **On stage transition**:
  - `state_write({mode: "pipeline", current_phase: "stage:<name>"})`
- **On completion**:
  - `state_write({mode: "pipeline", active: false, current_phase: "complete"})`

