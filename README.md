# thkt/github-labels

Centralized GitHub label configuration for thkt org dev/tool repositories.

Label scheme follows the Tier 3 lite design defined in [ADR-0059](https://github.com/thkt/dotfiles/blob/main/.claude/docs/decisions/0059-adopt-tier-3-lite-github-label-strategy.md). See [CONTRIBUTING.md](./CONTRIBUTING.md) for usage rules.

## What this repo does

- Defines the canonical label set in [`labels.yml`](./labels.yml).
- Synchronizes labels to target repos via `Micnews/github-label-sync` invoked by [`sync.yml`](./.github/workflows/sync.yml) workflow.
- Single source of truth: edit `labels.yml`, dispatch the workflow, target repo labels follow.

## Phase 1 status

Currently the workflow supports single-repo manual dispatch only. Multi-repo matrix sync, Issue Forms deployment, and retirement schedule are tracked in subsequent phases. See [SOW](https://github.com/thkt/dotfiles/blob/main/.claude/workspace/planning/2026-05-02-label-strategy/sow.md) for the full plan.

## Quick start

### 1. Local validation

Run the test script before committing changes to `labels.yml`:

```bash
bash test/validate-labels.sh
```

Checks performed:

- `labels.yml` parses with `yq`
- GitHub default 9 labels are present
- `priority:high` / `priority:medium` / `priority:low` exist with the graduated color palette
- Preserve list (`dependencies`, `ci`, `rust`) exists
- Every label has a description

### 2. Trigger sync

Dry-run first to preview changes:

```bash
gh workflow run sync.yml \
  --repo thkt/github-labels \
  -f target=thkt/yomu \
  -f mode=dry-run
```

Apply when satisfied:

```bash
gh workflow run sync.yml \
  --repo thkt/github-labels \
  -f target=thkt/yomu \
  -f mode=apply
```

## Token

`LABEL_SYNC_TOKEN` secret is required. Phase 1 uses a classic PAT (`repo` scope). Phase 3 migrates to fine-grained PAT with explicit per-repo scope, plus `monitor-token.yml` for expiry surveillance.

## Label set summary

| Group       | Labels                                                                        | Color discipline                |
| ----------- | ----------------------------------------------------------------------------- | ------------------------------- |
| Defaults    | bug, documentation, duplicate, enhancement, good first issue, help wanted, invalid, question, wontfix | preserved unmodified           |
| priority:\* | priority:high, priority:medium, priority:low                                  | graduated red -> orange -> yellow/green |
| Preserve    | dependencies, ci, rust                                                        | per-label (Dependabot interop)  |
| area:\*     | (lazy, per-repo opt-in via advanced-issue-labeler.yml)                        | placeholder, no enumeration yet |

## Related

- ADR-0059: Tier 3 lite GitHub label strategy
- SOW / Spec: `~/.claude/workspace/planning/2026-05-02-label-strategy/`
- Research: `~/.claude/workspace/research/2026-05-02-github-issue-label-strategy.md`
