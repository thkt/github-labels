# Contributing

Operational rules for thkt org repository labels. Decisions trace to [ADR-0059](https://github.com/thkt/dotfiles/blob/main/.claude/docs/decisions/0059-adopt-tier-3-lite-github-label-strategy.md).

## Tier 3 lite scheme

Tier 3 lite = research-derived Tier 3 design minus three elements:

| Removed              | Why                                                                          |
| -------------------- | ---------------------------------------------------------------------------- |
| effort:\*            | Solo maintainer does not need self-estimated effort labels                   |
| status:\* full set   | Initial deployment uses status:in-progress only; full set after Projects audit |
| area:\* eager enumeration | Lazy per-repo opt-in to avoid K8s-style area sprawl                     |

Tier 3 lite still inherits Tier 3 traits: priority + area prefix scheme, Issue Forms, advanced-issue-labeler automation, quarterly retirement schedule.

## Label rules

| Rule                                  | Detail                                                                  |
| ------------------------------------- | ----------------------------------------------------------------------- |
| 1 issue, at most 1 priority label     | priority:high / priority:medium / priority:low are mutually exclusive   |
| 1 issue, at most 1 status label       | status:\* presence indicates current workflow stage                     |
| 1 issue, multiple area labels allowed | area:\* labels are non-exclusive; an issue can span multiple components |
| Default = unlabeled priority          | No label means medium priority. Do not add priority:medium explicitly   |
| Preserve list is untouchable          | dependencies, ci, rust are preserved during sync (Dependabot interop)   |
| Color discipline                      | One color per prefix. priority:\* uses graduated red -> orange -> yellow |

## Adding a new label

1. Open a PR against `labels.yml` with the new entry.
2. Run `bash test/validate-labels.sh` locally before pushing.
3. After merge, dispatch `sync.yml` with `mode=dry-run` against one target repo to preview.
4. Dispatch `mode=apply` once dry-run output is acceptable.

## area:\* opt-in process

area:\* labels are not in `labels.yml` directly. They are added per-repo when issues span multiple components.

1. In the target repo, create `.github/advanced-issue-labeler.yml` with an `area` section listing the repo's components.
2. Update `.github/ISSUE_TEMPLATE/bug.yml` and `feature.yml` to include the area dropdown.
3. The `template-deploy.yml` workflow (Phase 4) propagates shared base templates; per-repo extensions stay in the target repo.

Trigger to opt in: a repository sees 2 or more issues that explicitly span different components.

## Migration with aliases

When renaming a label, use the `aliases` field in `labels.yml` to preserve issue history:

```yaml
- name: priority:high
  color: B60205
  description: Top of stack, work on next
  aliases:
    - P1
    - urgent
```

`Micnews/github-label-sync` will rename matching old labels to the canonical name without losing the issue association.

## Retirement schedule

Quarterly (1st of January, April, July, October) the `retirement.yml` workflow surfaces labels with zero applied issues for 6 months. Decision to retire is human, made via the retirement candidate issue.

## Safety rails

| Risk                                  | Safeguard                                                                  |
| ------------------------------------- | -------------------------------------------------------------------------- |
| Accidental deletion of unlisted labels | `--allow-removed-labels=false` is the default; do not flip without dual review |
| Token expiry                          | `monitor-token.yml` (Phase 3) creates an issue if `LABEL_SYNC_TOKEN` has under 14 days |
| Sync failure across multiple repos    | matrix `fail-fast: false` + summary job creates a failure issue (Phase 3)  |
