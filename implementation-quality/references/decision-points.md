# Decision Points — When to ASK vs PROCEED

A disciplined implementer asks for input at the right moments — not so often that the user becomes a babysitter, not so rarely that the implementer drifts off-course.

This file lists the situations where pausing is correct, and the situations where proceeding is correct. When in doubt: a 30-second ask is cheaper than a one-hour wrong implementation.

---

## When to ASK

### 1. Acceptance criterion is ambiguous

**Signal**: You read the criterion, and there are two reasonable interpretations.

**Example**:
> "User dapat melihat list transaksi"

Does "list" mean:
- A static list (all transactions ever)?
- Paginated (last N pages)?
- Filtered (current month only)?

**How to ask**:
> Acceptance criterion #3 ("user dapat melihat list transaksi") bisa diinterpretasikan beberapa cara:
> - A: paginated, 20 per page, scroll infinite
> - B: filtered by month, dropdown month picker
> - C: full list (all-time)
>
> Saya rekomendasikan **A** karena konsisten dengan list halaman lain di app. Sound good?

### 2. Existing function needs refactor to fit the new feature

**Signal**: The cleanest path to satisfy the issue requires changing a function used by other callers.

**Example**: Issue asks you to add a `userId` param to `sendNotification()`, but that function is called from 8 other places with the old signature.

**How to ask**:
> Untuk implement issue ini cleanly, `sendNotification()` perlu nambah param `userId`. Function ini dipanggil dari 8 tempat lain.
>
> Opsi:
> - A: Refactor semua 8 caller di PR ini (PR jadi besar tapi atomik)
> - B: Tambah `sendNotification(userId)` baru + deprecate yang lama; migrasi caller di PR terpisah
> - C: Tambah optional param `userId?` dengan default behavior (backward-compatible)
>
> Saya rekomendasikan **B** karena PR ini scope-nya cuma 1 feature. Mau saya proceed dengan B?

### 3. New dependency would simplify the implementation

**Signal**: You're about to reach for `npm install <package>` or `pubspec.yaml: <package>`.

**How to ask**:
> Implementasi ini bisa lebih simple kalau pakai package `xxx` (~5kb, MIT, last commit 2 minggu lalu). Alternatifnya kita build sendiri dengan ~30 baris.
>
> Pro pakai package: faster, battle-tested
> Pro build sendiri: no supply-chain risk, no maintenance dep
>
> Saya rekomendasikan **build sendiri** karena scope kecil. OK?

Never add a dependency silently. Even small ones.

### 4. Bug discovered in adjacent code

**Signal**: While implementing the issue, you notice a bug in nearby code that is NOT what this issue is about.

**Action**:
- DO NOT fix it in this PR (scope creep, makes review harder, mixes unrelated changes)
- DO file a separate issue with the bug, link from a PR comment

**How to communicate**:
> Note: pas saya touch `auth.ts` untuk issue ini, saya nemu bug terpisah — `validateEmail()` salah handle email dengan `+` (e.g. `ada+tag@example.com` ditolak). Saya bikin issue #45 untuk track itu. Tidak saya fix di PR ini karena scope-nya beda.

### 5. Pattern conflict (issue contradicts codebase convention)

**Signal**: The issue specifies an approach (e.g. "use Provider for state"), but the codebase uses something else (e.g. BLoC).

**How to ask**:
> Issue minta pakai Provider untuk state, tapi codebase TalentHub mobile pakai BLoC di mana-mana. Saya rekomendasikan ikut konvensi codebase (BLoC) supaya konsisten. OK saya update?
>
> Kalau ternyata Provider memang pilihan sengaja untuk feature ini, kasih tau alasannya — biar saya document di PR description.

### 6. Tests are missing / breaking / non-obvious to add

**Signal**: The implementation is straightforward, but how to test it isn't.

**How to ask**:
> Implementasi straightforward, tapi saya bingung approach test-nya:
> - Component depends on external service `X` yang nggak ada mock di project
> - Existing tests di area ini pakai pattern Y, tapi pattern Y kayaknya kurang cocok untuk case ini
>
> Saya bisa:
> - A: Bikin mock service `X` jadi pattern baru di project (tambah maintenance)
> - B: Skip unit test, tulis integration test pakai test server
> - C: Skip test untuk PR ini, file issue terpisah
>
> Saya rekomendasikan **A**. Sound right?

### 7. Issue scope is bigger than 1 PR

**Signal**: As you implement, you realize the issue is actually 2-3 logical units.

**How to ask**:
> Issue ini sebenernya 3 unit kerja yang independent:
> 1. Tambah endpoint baru POST /api/x
> 2. Update model User dengan field baru
> 3. Update mobile screen untuk consume endpoint baru
>
> Mau saya:
> - A: Split jadi 3 issue + 3 PR (lebih hygiene, sequencing jelas)
> - B: 1 issue, 3 PR (cepat tapi PR sequencing manual)
> - C: 1 PR besar (cepat tapi review jadi berat)
>
> Saya rekomendasikan **A**. Mau saya bikin 2 issue tambahan?

### 8. Security-sensitive decision

**Signal**: The implementation touches auth, secrets, user data, or external trust.

**Action**: ALWAYS ask before proceeding. Examples:
- Storing tokens — where? With what encryption?
- New role / permission — does this map to existing RBAC?
- Outbound URL — allowlist or wildcard?
- New CORS rule
- Disabling a security check "temporarily"

Never just "do the secure thing without telling the user" — they need to know it's a security decision so they can review.

---

## When to PROCEED (no ask needed)

### 1. Trivial style choice with clear local context

You renamed a local variable `t` to `transaction` because it's clearer. Don't ask. Just do.

### 2. Adding a helper file in the established folder structure

`lib/utils/dates.dart` already exists. You need a new date utility. Add to that file (or a sibling) without asking — the pattern is clear.

### 3. Adding a `const` wrapper / extracting a `const` widget

Pure micro-optimization with no downside. Just do.

### 4. Adding logging for debugging that you'll remove before commit

Add freely while developing. Remove before commit (no `console.log` in committed code).

### 5. Renaming a local variable / private method for clarity

Inside the scope of the function or class — go ahead. Document in commit body if non-obvious.

### 6. Reordering imports / formatting

If the project has a formatter (`prettier`, `dart format`, `gofmt`), run it. Don't ask permission to format.

### 7. Adding tests for code you wrote

Tests for the implementation you just did — proceed. Tests for code you didn't write but is in scope of the issue — also proceed.

### 8. Choosing between two equivalent local idioms

`for (final x in list)` vs `list.forEach((x) => ...)` — pick one, prefer the one nearby code uses. Don't ask.

---

## How to ask well

Bad ask:
> Is this OK?

Why bad: gives the user no context, no options, no recommendation. They have to do all the thinking.

Good ask:
> Saya nemu situasi X. Ada 2 opsi:
>
> - A: ... (trade-off: faster, but Y)
> - B: ... (trade-off: more robust, but Z)
>
> Saya rekomendasikan **B** karena Z lebih cocok dengan project ini. OK?

Why good: shows the situation, the options, the trade-offs, and a recommendation. The user can confirm / push back / pick the other. Minimum cognitive load.

---

## When the user has already said "just do it, ask less"

Some users want the agent to lean toward PROCEED. In that case:
- Skip asks for categories 1, 2, 5 above (ambiguity, refactor, pattern conflict) — make your best guess and document it in the PR description
- KEEP asks for 3, 4, 7, 8 (new dependency, adjacent bug, scope split, security) — these are irreversible / wider-impact and worth the friction

The user can always say "stop asking about X" after the fact. Better to over-ask early and learn the user's tolerance than under-ask and surprise them.

---

## Frequency budget

A reasonable rate is roughly:
- **0–1 asks** for a trivial bug fix
- **1–3 asks** for a typical feature (< 200 LoC)
- **3–6 asks** for a larger feature (> 500 LoC), spread across the work — not all upfront

If you find yourself at 6+ asks for a 200-LoC change, you're either:
- Working on a poorly-specified issue (push back: get the issue improved)
- Not pattern-matching the codebase well (read more first, ask less)
- Getting paralyzed by edge cases that don't matter (make the call, document in PR)
