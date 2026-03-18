# ADR-001: Managed Fork Strategy for Dreamware anything-llm

**Status:** Accepted
**Date:** 2026-03-18
**Deciders:** Engineering Team

---

## Context

Dreamware builds a customised version of [`Mintplex-Labs/anything-llm`](https://github.com/Mintplex-Labs/anything-llm), an actively maintained open-source LLM workspace. The upstream project ships frequent updates — new features, bug fixes, dependency upgrades, and breaking changes — that Dreamware needs to absorb in order to avoid falling behind and accumulating security debt.

At the same time, Dreamware has product-specific requirements that diverge from upstream: custom UI, additional integrations, modified business logic, and deployment-specific configuration. These customisations must survive each upstream merge without being lost or continuously re-applied by hand.

The core tension is: **how do we stay close to upstream while maintaining a stable, identifiable surface area of custom code?**

Key forces in play:
- Upstream is actively developed; patches and breaking changes arrive frequently.
- Dreamware customisations are expected to grow over time.
- The engineering team is small — manual merge work must be minimised.
- Diverging too far from upstream increases the long-term cost of merges.
- Custom code must be clearly discoverable for onboarding and auditing.

---

## Decision

We maintain a **managed fork** of `anything-llm` on GitHub (`Trapu20/dreamware-anything-llm`), with the following conventions enforced:

1. **Additive-first customisation** — Dreamware changes are introduced as new files wherever possible. Modifications to upstream files are allowed only when strictly necessary.

2. **Explicit change markers** — All in-place edits to upstream files are wrapped with:
   ```js
   // ===== DREAMWARE CUSTOM BEGIN =====
   // ... custom code ...
   // ===== DREAMWARE CUSTOM END =====
   ```

3. **Living deviation registry** — Every modified upstream file is listed in `.github/CUSTOM_FILES.md`, which must be kept up to date with every PR.

4. **Automated weekly upstream sync** — A GitHub Actions workflow (`upstream-sync.yml`) runs every Monday at 08:00 UTC and opens a PR merging `upstream/master` into `develop`. This surfaces conflicts as early as possible and keeps the merge surface small.

5. **Branch strategy** — A four-tier branch model (`main`, `develop`, `feature/*`, `upstream-sync/*`) separates production code from integration and experimental work, and prevents direct pushes to protected branches.

---

## Options Considered

### Option A: Managed Fork (chosen)

| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium |
| Upstream sync cost | Low (automated weekly PRs) |
| Custom code visibility | High (markers + CUSTOM_FILES.md) |
| Team familiarity | High (standard Git workflow) |
| Divergence risk | Low (small, marked diff surface) |

**Pros:**
- Upstream improvements (security patches, new models, UI fixes) can be absorbed with minimal manual effort.
- Custom code is explicitly bounded — easy to audit, easy to onboard new engineers.
- Automated sync surfaces conflicts early when they are still small and tractable.
- Standard GitHub PR workflow; no new tooling required.

**Cons:**
- Requires discipline to keep `CUSTOM_FILES.md` up to date.
- Merge conflicts on upstream-edited files still require manual resolution.
- If upstream undergoes a large refactor (e.g. renames a core module), the `DREAMWARE CUSTOM` blocks must be relocated.

---

### Option B: Full Independent Fork

| Dimension | Assessment |
|-----------|------------|
| Complexity | Low initially, High over time |
| Upstream sync cost | Very high (manual cherry-pick or none) |
| Custom code visibility | Low (no formal boundary) |
| Team familiarity | High |
| Divergence risk | Very high |

**Pros:**
- Complete freedom to restructure the codebase without merge constraints.
- No weekly sync overhead in the short term.

**Cons:**
- Upstream security patches, dependency updates, and bug fixes must be manually ported — or ignored entirely.
- Over time the codebases diverge significantly, making any future re-sync prohibitively expensive.
- No visibility into which parts of the code are Dreamware-specific vs. upstream; everything becomes "ours".
- Higher long-term maintenance burden for a small team.

---

## Trade-off Analysis

The key trade-off is **short-term convenience vs. long-term maintainability**.

A full independent fork removes the friction of weekly merge reviews entirely, but accumulates upstream debt silently. Security vulnerabilities in anything-llm would not reach Dreamware's deployment, new upstream features would require manual backporting, and the codebase would gradually become an island. For a small team maintaining a product that sits on top of an active OSS project, this is the worst long-term outcome.

The managed fork approach imposes a recurring, bounded cost (one PR review per week) in exchange for a continuously low divergence surface. The `DREAMWARE CUSTOM` markers and `CUSTOM_FILES.md` registry act as a forcing function: they make it immediately visible when a developer is about to modify upstream code, and they give reviewers a precise checklist for conflict resolution.

The additive-first rule further limits the merge conflict surface — a new file added by Dreamware will never conflict with upstream, whereas an in-place edit to a popular upstream file will conflict regularly.

---

## Consequences

**What becomes easier:**
- Absorbing upstream security patches and dependency upgrades (automated, low friction).
- Onboarding new engineers — `CUSTOM_FILES.md` is a single document that explains the entire Dreamware diff.
- Code review of upstream-sync PRs — reviewers know exactly where to look.
- Reverting a Dreamware customisation — the markers make it trivial to identify and remove.

**What becomes harder:**
- Large upstream refactors that touch files Dreamware has modified will require careful manual merge work.
- `CUSTOM_FILES.md` becomes stale if contributors forget to update it; this must be enforced via PR review checklist or CI lint.
- Keeping `DREAMWARE CUSTOM` markers from drifting out of sync when upstream restructures surrounding code.

**What we'll need to revisit:**
- If the number of modified upstream files grows significantly, consider introducing a more structured ADR or patch-tracking system.
- If upstream adopts an official plugin/extension API, evaluate migrating Dreamware customisations to that mechanism to eliminate in-place edits entirely.
- Periodically review whether the weekly sync cadence is appropriate as the team and product scale.

---

## Action Items

1. [x] Establish `upstream` remote pointing to `https://github.com/Mintplex-Labs/anything-llm.git` (push disabled)
2. [x] Implement `upstream-sync.yml` GitHub Actions workflow (Monday 08:00 UTC)
3. [x] Document branch strategy and protection rules in `CLAUDE.md`
4. [x] Create `.github/CUSTOM_FILES.md` as the living deviation registry
5. [ ] Add a PR template checklist item: "Updated `CUSTOM_FILES.md` if any upstream file was modified"
6. [ ] Consider a CI lint step that cross-checks `CUSTOM_FILES.md` against actual `DREAMWARE CUSTOM` markers in the codebase
