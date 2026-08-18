# Agent A Playbook — Implementation & Response

> This file contains the detailed procedures for **Agent A (Senior Engineer)**.
> For the shared protocol, handoff templates, and workflow overview, see [SKILL.md](../SKILL.md).

---

## Phase 0: Task Selection

Agent A picks the next uncompleted task from the todo list. Before coding, produce a **Task Claim**:

```
TASK CLAIM:
- Task ID: [from todo list]
- Task title: [description]
- Acceptance criteria: [list from spec]
- Files likely affected: [list]
- Relevant spec docs: [links]
- Estimated complexity: [low/medium/high]
- Prior human decisions relevant to this task: [none, or link/summary of any ESCALATE resolution]
```

If estimated complexity is LOW and touches only 1 file, consider skipping the dual-agent workflow and doing a self-review instead.

If this task is a continuation of a previously **ESCALATE**d task, the human's decision must be restated here explicitly — do not rely on either agent "remembering" a prior session.

---

## Phase 1: Implementation

**Activated agent-skills:**
- `incremental-implementation` — build in thin vertical slices
- `test-driven-development` — write failing test first, then make it pass
- `git-workflow-and-versioning` — atomic commits with descriptive messages

**Implementation checklist:**
- [ ] Read and understand the acceptance criteria before writing any code
- [ ] Follow the project's coding conventions (see AGENTS.md)
- [ ] Write tests before or alongside implementation (TDD)
- [ ] Each logical change gets its own commit
- [ ] **Commit messages stay factual** — describe *what changed*, not *why you believe it's the right call*. e.g. `fix: validate empty cart before checkout` — not `fix: validate empty cart, which I think is the correct approach here because...`. Persuasive reasoning belongs in the handoff's "Assumptions Made" / "Review Focus Areas" fields, where Agent B is expected to actively evaluate it — not in commit messages, which Agent B reads passively via `git log` during Phase 3 and which can leak Agent A's framing around the isolation barrier (see Prerequisites §5 in SKILL.md).
- [ ] Run the quality gate before handoff:

```bash
# Quality Gate — Agent A must pass ALL before handoff
# Adapt these commands to your project's tooling:
pnpm lint        # or: npm run lint, eslint ., etc.
pnpm typecheck   # or: npx tsc --noEmit, mypy, etc.
pnpm test        # or: npm test, pytest, go test ./..., etc.
pnpm build       # or: npm run build, cargo build, etc.
```

- [ ] Do NOT mark the task as done — that's Agent B's call after APPROVE

**What Agent A must NOT do:**
- Skip tests ("I'll add them later")
- Modify files outside the task scope
- Make assumptions about unclear requirements (ask the user instead)
- Ignore existing code style for a "better" approach
- Commit without passing the quality gate

---

## Phase 2: Producing the Handoff

After implementation and quality gate pass, Agent A produces a **Handoff Document** using `templates/handoff-a-to-b.md` (or the inline format in SKILL.md).

**Delivery rules:**
- Open a **fresh, isolated** Agent B session (see Prerequisites §5 in SKILL.md)
- Paste the full structured document — do not summarize or paraphrase
- Include the instruction: "Please review per the `dual-agent-pair-programming` skill, Phase 3. The spec documents are at [paths]. The todo list is at [path]."
- An informal "just look at the latest commit" handoff is a red flag, not an acceptable shortcut

---

## Phase 5: Response to Review (对抗审查)

**Before doing anything else, sync the branch.** If Agent B applied any `[reviewer-fix]` commits, run `git pull` / `git log` to confirm the current state before making further changes — do not edit from a stale local state.

If Agent B issued REQUEST CHANGES, respond to each Critical or Important finding with one of:

```
FINDING RESPONSE:

1. ✅ ACCEPT — [finding description]
   Action: [what Agent A will change and where]

2. ❌ DISAGREE — [finding description]
   Reason: [why Agent A believes the current implementation is correct]
   Evidence: [spec reference, test case, or technical justification — must point to a real,
              checkable location (file:line, spec section, test name), not a paraphrase]

3. ⚠️ ESCALATE — [finding description]
   Reason: [why this requires human judgment — e.g., spec is ambiguous]
   Options: [option A vs option B, with tradeoffs for each]
```

**Rules for DISAGREE:**
- Must cite evidence: a spec reference, a passing test, or a technical justification — and the citation must be checkable (Agent B will open it)
- "I think it's fine" without evidence is not a valid DISAGREE
- Do not cite a spec section, test, or file from memory without confirming it still says what you claim — re-read it before citing it
- If Agent B counter-disagrees with its own evidence, escalate to human after 1 more cycle

After addressing all findings:
- Implement changes for all ACCEPT items
- Re-run the full quality gate
- Produce a new Handoff A→B referencing the previous review cycle
- Include the finding responses in the new handoff

---

## Agent A's Skill Activation Map

| Phase | Activate | Purpose |
|-------|----------|---------|
| Understanding the task | `planning-and-task-breakdown` | Decompose if needed |
| Implementing code | `incremental-implementation` | Build in vertical slices |
| Writing tests | `test-driven-development` | Red-Green-Refactor |
| Designing APIs | `api-and-interface-design` | Contract-first |
| Building UI | `frontend-ui-engineering` | Component architecture |
| Pre-handoff self-check | `code-review-and-quality` | Self-review before handoff |
| Git operations | `git-workflow-and-versioning` | Atomic commits |
