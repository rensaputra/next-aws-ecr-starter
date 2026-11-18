# To-Do

Deferred work items for the deploy pipeline. Add new items here as they come up.

---

## 1. Make `deploy-prod` wait for the dev rollout to actually finish

**Status:** Not started

**Context.** The deploy stages trigger the infra repo with a
`repository_dispatch` event (`web-app-image-pushed`). That call is
*fire-and-forget*: the `curl` step succeeds as soon as GitHub accepts the event.
It confirms the event was **sent**, not that the infra repo's ECS rollout
**finished** (or succeeded).

Today `deploy-prod` depends on `deploy-dev` via `needs: deploy-dev`. But because
the dispatch is fire-and-forget, "deploy-dev succeeded" currently means "the dev
dispatch was sent," **not** "dev is live and healthy." So prod can be approved
and dispatched before the dev rollout has actually completed.

**Goal.** Make `deploy-dev` reflect the real outcome of the dev rollout, so that
`deploy-prod` only becomes eligible for approval after dev is genuinely deployed
and healthy.

**Possible approaches (to evaluate, not yet chosen):**

- **Poll the infra run.** After dispatching, have `deploy-dev` poll the infra
  repo's workflow run status via the GitHub API until it completes, then pass or
  fail accordingly. Needs a way to correlate the dispatch with the specific run
  it started (e.g. a correlation id in the payload).
- **Callback / status report.** Have the infra workflow report back to this repo
  when the rollout finishes (e.g. a `repository_dispatch` in the reverse
  direction, a commit status, or a deployment status update), and have
  `deploy-dev` wait on that.
- **Poll ECS directly.** Have `deploy-dev` assume the AWS role and wait on the
  ECS service to reach a stable/healthy state (e.g. `aws ecs wait
  services-stable`), independent of the infra workflow.

**Open questions:**

- How do we correlate a dispatch with the exact infra run it triggered?
- What counts as "dev is healthy" — infra workflow success, ECS service stable,
  or an app-level health check?
- Does the PAT / OIDC role have the permissions each approach needs (read infra
  runs, or describe the ECS service)?

**Done when:** `deploy-prod` cannot be approved/dispatched until the dev rollout
has verifiably completed successfully, with a clear failure surfaced on
`deploy-dev` if it doesn't.
