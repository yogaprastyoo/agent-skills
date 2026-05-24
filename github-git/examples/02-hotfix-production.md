# Example 02 — Hotfix to production

The emergency path. Use this when production is broken and you need a fix in `main` ASAP — bypassing the normal `develop` → `main` release flow.

**Scenario**: 2 AM. PagerDuty fires. Production `/api/checkout` is returning 500 for ~30% of requests. You traced it to a null-handling bug in the payment gateway adapter introduced in last week's release.

---

## Hotfix flow vs feature flow

Normal flow: branch from `develop` → PR to `develop` → eventually released to `main`.

Hotfix flow: branch from `main` → fix → PR to `main` → ALSO merge back to `develop` so the fix isn't lost in the next release.

The key differences are bolded throughout this walkthrough.

---

## Step 0 — Confirm the issue is real

Before you start a hotfix, make sure:
1. The bug reproduces (don't hotfix on a hunch)
2. It's actually severity-critical (data loss, security, major revenue impact)
3. Rollback isn't faster (sometimes `gh release create previous-tag --target main` is the right call)

For our scenario: yes, reproduces. 30% of checkouts failing = critical.

---

## Step 1 — File the hotfix issue

```
/git-issue fix: handle null gateway response in checkout
```

Or directly:

```bash
gh issue create --title "fix: checkout returns 500 when gateway returns null" --body "$(cat <<'EOF'
## Description

Production `/api/checkout` returns 500 for ~30% of requests since the
deploy at 2026-05-23T14:32Z. Traced to `src/services/payment/gateway.ts`
not handling a null response from the Stripe gateway.

## Context

The new gateway adapter introduced in PR #84 assumes `gateway.charge()`
returns a non-null result. Stripe occasionally returns null (documented
behavior when their idempotency cache is warm), which causes a TypeError
on line 47.

## Acceptance Criteria

- [ ] `/api/checkout` returns 200 (or a proper 4xx error) when gateway returns null
- [ ] Add a unit test simulating null gateway response
- [ ] No regression in the existing happy-path test

## Severity

- [x] Critical — production down, revenue impact

## Technical Notes

This must hotfix `main` directly (PR to main, not develop). After main is
patched, the same fix needs to merge into develop so it isn't lost in the
next release.
EOF
)" --label "bug"
```

Output: `https://github.com/.../issues/99`

---

## Step 2 — Branch from main (**not develop**)

```bash
git checkout main                # NOT develop
git pull origin main
git checkout -b hotfix/99-null-gateway-response
```

The `hotfix/` prefix triggers special handling in `/git-pr`:
- Auto-detected base branch = `main` (not `develop`)
- Different merge strategy (merge commit, not squash — preserves traceability)

---

## Step 3 — Fix the bug

```typescript
// src/services/payment/gateway.ts

async charge(amount: number, customerId: string) {
  const result = await this.stripe.charges.create({ amount, customer: customerId });

  // Hotfix: Stripe sometimes returns null when idempotency cache is warm
  if (!result) {
    throw new GatewayUnavailableError('Gateway returned null; retry after 1s');
  }

  return result;
}
```

Add a test:

```typescript
// tests/payment/gateway.test.ts

it('throws GatewayUnavailableError when gateway returns null', async () => {
  mockStripe.charges.create.mockResolvedValue(null);
  await expect(gateway.charge(1000, 'cus_123')).rejects.toThrow(GatewayUnavailableError);
});
```

Run tests locally — make sure they pass.

---

## Step 4 — Commit

```
/git-commit
```

Claude drafts:

```
fix(payment): handle null response from Stripe gateway

Stripe returns null occasionally (warm idempotency cache). Previously
this caused a TypeError → 500 on /api/checkout. Now we throw
GatewayUnavailableError which surfaces as a proper 503 to the client.

Closes #99
```

You commit.

---

## Step 5 — Push and PR to **main**

```
/git-pr
```

Claude detects `hotfix/` prefix → base = `main`. Generates the PR:

```bash
gh pr create --base main \
  --title "[Hotfix] Handle null gateway response in checkout" \
  --body "$(cat <<'EOF'
## Description

Hotfix for production incident at 2026-05-24T02:14Z. `/api/checkout`
returning 500 for ~30% of requests due to unhandled null from Stripe.

## Changes

- Added null check in `src/services/payment/gateway.ts`
- New unit test for null gateway response

## Related Issues

Closes #99

## Type of Change

- [x] Bug fix

## Testing Performed

- [x] Unit test added and passing
- [x] Manual: simulated null response in dev, confirmed 503 returned
- [x] Existing happy-path test still passes

## Self-Review Checklist

- [x] Self-review performed
- [x] No new secrets
- [x] Fix is minimal — only what's needed to stop the bleeding

## Notes for Reviewers

This is a hotfix to main, not develop. Will be cherry-picked into develop after merge (see Step 7).
EOF
)" --label "bug" --assignee "@me"
```

Output: `https://github.com/.../pull/100`

---

## Step 6 — Fast review and merge

For a critical hotfix, normal review SLA doesn't apply. Ping the on-call reviewer directly. Once approved:

```bash
gh pr merge 100 --merge --delete-branch     # NOT --squash for hotfix
```

The `--merge` strategy (merge commit) is used for hotfix/release branches to preserve the audit trail. The merge commit itself is the trigger for production deploys (depending on your CI setup).

---

## Step 7 — Cherry-pick the fix into develop

This is the easy-to-forget step. If you skip it, the fix exists in `main` but NOT in `develop`. Next release will reintroduce the bug.

```bash
git checkout develop
git pull origin develop

# Find the hotfix merge SHA on main
git log main --oneline | head -5

# Cherry-pick it
git cherry-pick <merge-sha> -m 1     # -m 1 because it's a merge commit
```

If there are conflicts (develop has diverged from main), resolve them like a normal merge conflict (see `examples/03-conflict-resolution.md`).

Push develop directly? **No.** Open a PR:

```bash
git checkout -b hotfix-backport/99-null-gateway
git push -u origin hotfix-backport/99-null-gateway
gh pr create --base develop \
  --title "[Backport] Hotfix #99 null gateway response" \
  --body "Backports the hotfix from #100 into develop so the fix survives the next release.

Closes #99 (also closed by #100, but linking again for traceability)"
```

Merge with `--squash` (it's a "feature" by branch convention):

```bash
gh pr merge --squash --delete-branch
```

---

## Step 8 — Post-incident

Don't skip this:

- Update the incident log (Slack, Notion, wherever you track them)
- Schedule a follow-up issue for proper fix if the hotfix was a band-aid
- Add a longer-term action: improve Stripe response monitoring, add retry logic, etc.

The hotfix landed. The bug is patched. The team learned something.

---

## Variations

- **Multi-branch hotfix** — if you support multiple production versions (`release/1.x`, `release/2.x`), cherry-pick into each.
- **Hotfix that can't go via PR** — if GitHub is down and you must `git push origin main` directly: the `pre-push` git hook will refuse. Bypass with `git push --no-verify` (intentional escape valve). Document the bypass in the incident postmortem.
- **Hotfix that turns out wrong** — revert immediately. See `references/advanced-operations.md` → "Revert a merged PR".
