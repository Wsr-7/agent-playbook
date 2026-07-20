---
name: bootstrap
description: Bootstrap a repo into this skill workflow — scan the project, then create STATE.md, a lessons file, and a scripts/gate.ps1 seeded with the project's real build/test commands. Use when the user says "bootstrap this project", "初始化项目工作流", "接入 skills 工作流", or when groundwork/spec-to-delivery runs in a repo that has no STATE.md or gate script.
---

# Bootstrap

Wire a project into the workflow the engines assume: one state file, one lessons file, one deterministic gate. Idempotent — never overwrite anything that already exists; report it as skipped instead.

## 1. Scan

Read, don't guess: README, the package manifest(s) (package.json / pom.xml / pyproject.toml / go.mod / *.csproj), CI config, existing CLAUDE.md / AGENTS.md, and the docs layout. Extract: the real build / lint / test commands, the default branch, whether the repo keeps local-only working docs (a gitignored `.local/` or similar), and conventions worth preserving.

## 2. STATE.md

If none exists (check root, `.local/`, `docs/`), create one seeded with what the scan learned. Location follows the repo's convention: root when shared docs are committed, the local docs dir when working docs are gitignored. Skeleton:

```md
# Loop State · <project>

## 当前阶段
- <one line: where the project is; active plan doc if any>

## In progress
- 无

## 待人工验证 / 决策
- 无

## Gate
- `scripts/gate.ps1`: <what it checks>. Run before any review/acceptance.

## Lessons
- 见 <lessons file path>
```

## 3. Gate

If no `scripts/gate.*` exists, create `scripts/gate.ps1`: section 1 runs the project's real check commands from step 1 (FAIL on non-zero exit, print the tail of failing output); section 2 checks git state (dirty tree → FAIL with "commit your checkpoints"; unpushed / no upstream → WARN); end with `GATE: PASS` / `GATE: FAIL` and exit 0 / 1. Every verdict comes from an exit code — no model judgment inside the gate.

If several check commands are plausible, ask one question with a recommended default. Then **run the gate once and report the verdict** — an unverified gate is not a gate.

## 4. Lessons

If no lessons file exists, create one (default `.local/tasks/lessons.md` when `.local/` is the convention, otherwise `docs/lessons.md`) with a single seed line: `<today> — bootstrapped into skill workflow`.

## 5. Report

List: created / skipped-because-existing, the gate's first verdict with evidence, and any items needing human confirmation (e.g. which test command the gate should run). Suggest the SessionStart STATE-injection hook if the user hasn't installed it.
