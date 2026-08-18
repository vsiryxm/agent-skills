# Agent B Playbook — Review & Verdict

> This file contains the detailed procedures for **Agent B (Tech Lead / Reviewer)**.
> For the shared protocol, handoff templates, and workflow overview, see [SKILL.md](../SKILL.md).

---

## Context Isolation Self-Check (开始审查前必做)

**Before reading the handoff or starting any review, perform this self-check:**

> "Does my current context contain ANY of Agent A's reasoning, chat history,
> or internal notes beyond what appears in the handoff document I was given?
> If yes: STOP. Notify the user that isolation may be compromised and ask them
> to start a clean session. Then proceed using ONLY the handoff document,
> spec docs, and actual code/git diff."

This check exists because even well-intentioned humans sometimes paste Agent A's full chat transcript "to save time." If you detect extra context, you are the last line of defense — do not silently proceed.

---

## Phase 3: Review

Agent B receives the handoff and conducts a structured review, **in a session isolated from Agent A** (see Prerequisites §5 in SKILL.md).

**Activated agent-skills:**
- `code-review-and-quality` — five-axis review (correctness, readability, architecture, security, performance)
- `security-and-hardening` — security-focused audit
- `doubt-driven-development` — adversarial verification of non-trivial claims, including cited evidence

### Layer 1: Spec Compliance Check (合规性检查)

Cross-reference every acceptance criterion against the actual implementation:

```
SPEC COMPLIANCE:
- [ ] Criterion 1: [quote from spec] → Verified in [file:line] → PASS/FAIL/PARTIAL
- [ ] Criterion 2: [quote from spec] → Verified in [file:line] → PASS/FAIL/PARTIAL
...
Verdict: ALL CRITERIA MET / GAPS FOUND: [list gaps]
```

**This layer determines the verdict.** If any acceptance criterion FAILs, the verdict must be REQUEST CHANGES.

**Do not skip Layer 2/3 just because Layer 1 failed.** Even when Layer 1 fails, continue through Layer 2 and Layer 3 in the same pass and record everything you find. The goal is for Agent A to receive *all* known issues in a single handoff, not to trickle them out one review cycle at a time — each extra cycle burns against the 3-cycle convergence limit.

### Layer 2: Five-Axis Code Review (正确性审查)

Apply the five-axis review from `code-review-and-quality`:

1. **Correctness** — Does the code do what the spec says? Edge cases? Error paths?
2. **Readability** — Can another engineer understand this without explanation?
3. **Architecture** — Does it fit the system design? Clean module boundaries?
4. **Security** — Input validation? Auth checks? Injection risks? Secrets in code?
5. **Performance** — N+1 queries? Unbounded operations? Missing pagination?

Categorize every finding with severity:
- **Critical:** — Blocks approval. Security vulnerability, data loss risk, spec violation.
- **Important:** — Should fix before approval. Missing test, wrong abstraction, poor error handling.
- **Suggestion:** — Optional improvement. Naming, style, alternative approach.

### Layer 3: Completeness Check (完整性检查)

Look for what's **missing**, not just what's wrong:

- [ ] Are there edge cases the spec implies but doesn't explicitly state?
- [ ] Are error messages user-friendly and i18n-ready (if applicable)?
- [ ] Are database transactions used where atomicity is needed?
- [ ] Are there race conditions in concurrent scenarios?
- [ ] Is logging/observability in place for new critical paths?
- [ ] Are there missing tests for boundary conditions?
- [ ] Does the change handle backwards compatibility?
- [ ] **Are the tests actually testing behavior?** Watch for tests that mock away the exact logic under test, assert tautologies (e.g. `expect(true).toBe(true)`), or only exercise the happy path while claiming "edge cases covered."

### Quality Gate Re-verification

Agent B independently runs the quality gate — do not trust Agent A's reported results:

```bash
# Agent B verifies independently
git log --oneline -10     # review recent commits
git diff --stat HEAD~N    # verify the actual changes match the handoff
pnpm lint
pnpm typecheck
pnpm test
pnpm build
```

### Reviewing a Re-submission (Review Cycle ≥ 2)

If the handoff includes Finding Responses from a previous cycle, treat each response as **a claim to verify, not a fact**:

- For **✅ ACCEPT**: confirm the described change actually happened in the diff.
- For **❌ DISAGREE**: **open the cited spec section, test case, or file yourself.** Confirm it exists and actually says what Agent A claims. A citation that looks well-formatted is not evidence — LLMs can produce a plausible-sounding reference to something that doesn't say what's claimed, or doesn't exist at all. Only accept a DISAGREE once you've independently verified the cited evidence.
- For **⚠️ ESCALATE**: confirm this genuinely requires human judgment (ambiguous spec, conflicting requirements) rather than being a disagreement Agent B could resolve with more investigation.

---

## Phase 4: Producing the Verdict

Agent B produces a **Review Verdict** using `templates/handoff-b-to-a.md` (or the inline format in SKILL.md).

**Rules for Agent B's direct fixes (if any):**
- Must be minimal (<10 lines per fix) — this keeps B in the reviewer role, not the reimplementation role
- Must be tagged with `[reviewer-fix]` in the commit message
- Must include a reason
- Must be limited to obvious bugs only
- Structural changes or design decisions go back to Agent A

---

## Agent B's Skill Activation Map

| Phase | Activate | Purpose |
|-------|----------|---------|
| Code review | `code-review-and-quality` | Five-axis review |
| Security audit | `security-and-hardening` | OWASP, auth, input validation |
| Adversarial check | `doubt-driven-development` | Challenge Agent A's claims — including cited evidence |
| Performance review | `performance-optimization` | N+1, unbounded ops |
| Test quality | `test-driven-development` | Verify test adequacy |
