---
name: dual-agent-pair-programming
description: Orchestrates two AI agents in a structured pair programming workflow — Agent A (Senior Engineer) implements requirements per spec, while Agent B (Tech Lead / Reviewer) reviews for correctness, completeness, and spec compliance. Use when implementing features that touch multiple files, involve core business logic, or require high correctness guarantees. Ensures coding stays aligned with PRD and todo list through adversarial review cycles with standardized handoff protocols.
version: 1.4
---

# Dual AI Agent Pair Programming

## Overview

Single-agent development suffers from hallucination, laziness, and spec drift — the agent confidently writes plausible code that doesn't match the actual requirements. This skill orchestrates two agents in a structured adversarial collaboration:

- **Agent A (Senior Engineer)** — implements tasks strictly following the PRD, spec docs, and todo list
- **Agent B (Tech Lead / Reviewer)** — reviews A's work for spec compliance, correctness, and completeness; may propose minimal fixes

Alternating review cycles with a standardized handoff protocol ensure no task is marked done without independent verification. **The goal is singular: the implementation faithfully matches the spec with no omissions.**

**Why this works — and how it silently fails:** the value comes entirely from Agent B's *independence*. If B's judgment is contaminated by A's reasoning, or B accepts A's claims at face value, the workflow degrades into an expensive rubber stamp. Every rule below that says "independently" or "verify" protects that independence — treat those rules as non-negotiable.

> **Role-specific details** live in separate playbooks so each session stays focused:
> - Agent A: `references/agent-a-playbook.md`
> - Agent B: `references/agent-b-playbook.md`
> - Templates: `templates/handoff-a-to-b.md`, `templates/handoff-b-to-a.md`

## Quick Start

1. **Agent A session:**
   ```
   Activate `dual-agent-pair-programming`. I am Agent A (Engineer).
   Spec docs: [paths]. Todo list: [path]. Begin Phase 0.
   ```
2. **On A's handoff**, open a **new, clean Agent B session** (no shared history — Prerequisites §5):
   ```
   Activate `dual-agent-pair-programming`. I am Agent B (Reviewer).
   Review per Phase 3. [paste handoff]
   ```
3. **On B's verdict**, copy it back to Agent A. Repeat until **APPROVE** or **ESCALATE**.

## Prerequisites — Read Before Use

### 1. Declare Your Agent Tools

Tool-agnostic — A and B can be any AI coding tool (Claude Code, Cursor, Gemini CLI, Antigravity, Codex, Copilot, etc.). Declare both **before starting**:

```
Agent A (Engineer): Claude Code (claude-opus-5)
Agent B (Reviewer): Gemini CLI (gemini-3.6-flash)
```

**Strong recommendation:** use **different models or tools** for A and B. Same-model agents share training data and biases — a mistake A doesn't notice is disproportionately likely to be one B also misses. Cross-model pairing surfaces a meaningfully different set of issues. (Well-motivated heuristic, not a measured statistic — don't cite specific percentages.)

### 2. Ensure Spec Documents Exist

- [ ] **PRD** — e.g., `docs/PRD.md`
- [ ] **Architecture docs** — system design, data model, tech stack
- [ ] **API specs** — endpoints, request/response schemas
- [ ] **DDL / data model** — database schema definitions
- [ ] **Todo list** — task breakdown with acceptance criteria (plan.md, task.md, or issue tracker)

### 3. Baseline Context Loading

Both agents load at session start:

1. AGENTS.md / CLAUDE.md / GEMINI.md — project behavioral constraints
2. README.md — project overview
3. package.json / go.mod / Cargo.toml — dependencies and scripts
4. docs/PRD.md — requirements index; load sub-docs as needed
5. Architecture docs relevant to the current task
6. Current branch, `git status`, recent commits
7. The active todo list / task plan

**Rule:** never overwrite or lose existing changes — check `git status` and `git stash` if needed before starting.

### 4. Install and Activate Agent-skills

Works best combined with skills from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), installed and available to both agents. Each agent activates specific skills per phase — see the Skill Activation Maps in the playbooks.

### 5. Session Isolation for Agent B (独立性隔离) — Critical

Agent B's entire value comes from being an *independent* check on A. That independence is easy to lose by accident:

- B's session MUST be **fresh** — no shared conversation history, memory, or context from A's session — on **every** review cycle.
- B's context is limited to: the spec documents, the actual code / git diff, and the handoff document. It must **not** see A's chain of reasoning, internal notes, or how A talked itself into a decision.
- If your tooling can accidentally reuse a session (same terminal/IDE window, shared memory feature), explicitly confirm isolation before Phase 3 begins.

**Rule of thumb:** if B can explain *why* A made a decision without that explanation appearing in the handoff itself, isolation has been broken.

**Isolation can still leak across different vendors' tools:**
- **The human pasting more than the handoff** — paste only the structured handoff document, never A's full chat transcript or reasoning log.
- **Git history** — if A's commit messages argue for a decision ("chose X because I think Y is better…"), that reasoning reaches B through `git log`. This is why commit messages must stay factual (agent-a-playbook, Phase 1).

> B performs a **Context Isolation Self-Check** at the start of Phase 3 (agent-b-playbook).

### 6. Authorization Boundaries (授权边界)

| Boundary Level | Category & Operations | Action / Behavior |
|----------------|------------------------|-------------------|
| **Always Allow** (预授权) | • Reading project files & documentation<br>• Editing files explicitly within task scope<br>• Creating or updating unit/integration tests<br>• Running quality gate commands (`lint`, `typecheck`, `test`, `build`)<br>• `git status`, `git diff`, `git add`, `git commit` on the current branch | Agents execute autonomously without prompting the user. |
| **Ask First** (需审批) | • Database schema changes (DDL / migrations)<br>• Adding or updating external package dependencies<br>• Modifying system configuration files or CI/CD pipelines<br>• Editing files outside the specified task scope<br>• Switching, creating, or merging Git branches | Agent MUST stop, present options/tradeoffs, and wait for human confirmation. |
| **Never** (绝对禁止) | • Committing secrets, API keys, or credentials<br>• Deleting existing passing unit or integration tests<br>• Directly editing environment secret files (`.env`)<br>• Interacting with or deploying directly to production environments<br>• Skipping quality gate verification checks | Strictly prohibited. Agents MUST NOT perform or ask to perform these actions. |

## When to Use

**Activate when:**
- The task touches more than 1 file
- Core business logic, financial calculations, or security-sensitive code
- Database schema changes
- Complex acceptance criteria
- High confidence needed that implementation matches spec
- History shows the AI agent drifting from requirements

**Do NOT use when:**
- Single-file, single-function trivial changes
- Pure formatting, comment, or documentation changes
- Mechanical refactors (rename, move) where correctness is obvious
- The cost of the review cycle exceeds the risk of the change

**Keep each handoff review-sized.** If a change pushes past a few hundred lines of diff or touches many unrelated files, use `planning-and-task-breakdown` to split it into sub-tasks, each with its own Phase 0→6 cycle.

## The Workflow

```
- [ ] Phase 0: Task Selection — A claims a task (agent-a-playbook)
- [ ] Phase 1: Implementation — A codes, tests, commits (agent-a-playbook)
- [ ] Phase 2: Handoff A→B — A produces the structured handoff document
- [ ] Phase 3: Review — B performs the three-layer review (agent-b-playbook)
- [ ] Phase 4: Verdict — B outputs the verdict (rules below)
- [ ] Phase 5: Response — A addresses findings (agent-a-playbook)
- [ ] Phase 6: Convergence — APPROVE, or loop to Phase 2 (max 3 cycles)
```

### Handoff A → B (Phase 2)

Fill in **every field** of `templates/handoff-a-to-b.md` (read the template from disk when producing the handoff). Required: task ID/title/branch/commits/review cycle; what was implemented; acceptance-criteria status with file:line; files changed; quality-gate results; review focus areas; assumptions; spec references. An informal "just look at the latest commit" handoff is a red flag, not a shortcut.

### Verdict Output Rules (Phase 4) — token-efficient by design

| Verdict | Session output | File write |
|---|---|---|
| **APPROVE** | Concise form below — verdict + one-line basis + gate results | **None.** Do NOT write `.pair-review/**/handoff-b-to-a-r*.md` |
| **REQUEST CHANGES** | Structured findings per `templates/handoff-b-to-a.md`: Layer-1 result + severity-categorized findings (file:line + fix) + verified gate results + next action. Omit sections with nothing to say | On demand — when findings need cross-session tracking or the user wants archival |
| **ESCALATE** | Same structured form, plus the disagreement and options for the human | On demand — but the human's resolution must always be archived |

**APPROVE output (session only):**

```
VERDICT: APPROVE — Task [ID] — cycle [N]
Basis: [one line — e.g. all N acceptance criteria verified (file:line); lint/type/test/build all PASS]
[optional one-line remark]
```

Do not pad APPROVE verdicts into full documents — findings lists, praise sections, and empty template fields add tokens without adding information. A full document is warranted only when there is something to fix or decide.

### Phase 6: Convergence

| Condition | Action |
|-----------|--------|
| B issues **APPROVE** | Task done ✅. A marks it complete in the todo list. |
| **3 review cycles** without APPROVE | **ESCALATE to human.** The disagreement is information, not a reason to keep looping. |
| A and B agree to **ESCALATE** | Human reviews the disagreement and makes the call. |

**Anti-pattern:** do NOT loop more than 3 times. Still disagreeing after 3 rounds usually means the spec is ambiguous — that needs human clarification, not more agent rounds.

**After a human resolves an ESCALATE:** record the decision in the handoff archive and carry it into the next Phase 0 Task Claim. Do not assume either agent's next session will "remember" it.

### Handoff Archive

```
.pair-review/
└── task-{id}/
    ├── handoff-a-to-b-r1.md    # always — A's claim record and B's review input
    ├── handoff-b-to-a-r1.md    # non-APPROVE verdicts / on demand
    └── ...
```

- A→B handoffs are always archived — they are the record of what was claimed and B's review input.
- B→A verdict files are written only for REQUEST CHANGES / ESCALATE, or on user request. An APPROVE lives in the session output; the todo list "done" mark is the durable record.
- Dotfile directory keeps review artifacts out of product docs; add `.pair-review/` to `.gitignore` if you don't want review history in version control.
- Human decisions on ESCALATE'd tasks must always be archived — the one thing a fresh session cannot reconstruct.

## Git Workflow

Both agents operate on the **current working branch**, managed by the human user.

```
current-branch (managed by user)
  ├── commit: "feat: implement X"                [Agent A]
  ├── commit: "test: add tests for X"            [Agent A]
  ├── commit: "[reviewer-fix] fix edge case Y"   [Agent B, if applicable]
  └── commit: "fix: address review findings #2"  [Agent A, after review]
```

**Rules:**
- Branch creation, switching, and merging is controlled by the human user (or approved under Ask First)
- B's direct minimal fixes are tagged `[reviewer-fix]` in commit messages
- Tasks are marked complete only after B's APPROVE
- Both agents inspect `git status` before starting any work
- A re-syncs (`git pull` / `git log`) before Phase 5, in case B committed `[reviewer-fix]` changes
- Neither agent overwrites, discards, or resets uncommitted changes without explicit human instruction

## Common Rationalizations

| Rationalization | Why it's wrong | Correct Action |
|---|---|---|
| "Agent B is just slowing us down" | Without independent review, spec drift compounds silently. | Complete the full handoff cycle. Skip only when the task meets "Do NOT use" criteria. |
| "I'll skip the handoff template" | Unstructured handoffs waste tokens. The template is the protocol. | Use `templates/handoff-a-to-b.md` and fill in every field. |
| "I'll write the full APPROVE verdict file for the record" | The file adds tokens without information; the todo "done" mark already records the approval. | Output the concise APPROVE conclusion in session; write no file (Phase 4 rules). |
| "Both agents agree, so it must be correct" | Same-model agents share blind spots. Agreement proves consistency, not correctness. | Use different models. Schedule periodic human spot-checks. |
| "The tests pass, so B can just approve" | Tests don't catch spec drift, missing features, or architectural problems. | B completes all three review layers regardless of test results. |
| "Agent B should rewrite Agent A's code" | B's role is review, not reimplementation. | B issues REQUEST CHANGES. Direct fixes limited to obvious bugs <10 lines (agent-b-playbook). |
| "We've been going back and forth too long" | If 3 rounds can't converge, the spec is ambiguous. | Issue ESCALATE TO HUMAN. Wait for human decision. |
| "This change is too small for review" | "Small" changes to core business logic still warrant review. | Check "When to Use". If core logic is involved, run the full cycle. |
| "Same model is fine" | Same-model pairs share training biases and blind spots. | Declare different tools/models (Prerequisites §1). |
| "The evidence Agent A cited sounds right" | LLMs can produce plausible citations to things that don't exist or don't say what's claimed. | B opens the cited file/section itself (agent-b-playbook, Re-submission). |
| "Agent B can reuse Agent A's context, saves tokens" | If B sees A's reasoning, B inherits A's framing and blind spots. | Start B in a fresh, isolated session (Prerequisites §5). |

## Red Flags

- A skipping tests ("I'll add them in the next commit")
- B rubber-stamping with "LGTM" without evidence of actual review
- Handoff documents omitting the acceptance-criteria status
- More than 3 review cycles without escalation to human
- Both agents using the same model and same tool
- Quality gate skipped "because it's a small change"
- A marking a task done before B's APPROVE
- Handoff delivered informally ("just look at the latest commit")
- B's session having visibility into A's reasoning/chat history
- Commit messages that argue for a decision instead of factually describing the change
- A single handoff covering a diff too large for a real review
- Review that only checks code quality (Layer 2) while skipping spec compliance (Layer 1)
- A resolved ESCALATE decision not written down anywhere
- Full `handoff-b-to-a` files written for APPROVE verdicts (token waste — Phase 4 rules)

## Verification

After completing a task via this workflow:

- [ ] A implemented against the spec's acceptance criteria
- [ ] A passed the quality gate before handoff
- [ ] Handoff A→B followed the template with all required fields
- [ ] B's session was isolated from A's reasoning/chat history
- [ ] B performed all three review layers, even when Layer 1 failed
- [ ] B independently ran the quality gate
- [ ] Non-APPROVE verdicts included a clear verdict with categorized findings
- [ ] APPROVE verdicts were concise session outputs — no b-to-a file written
- [ ] All Critical findings were resolved before APPROVE
- [ ] A synced the branch before responding to review
- [ ] Convergence reached within ≤ 3 cycles (or escalated to human)
- [ ] The task was marked done only after APPROVE
- [ ] Different models/tools were used for A and B (strongly recommended)
- [ ] Any ESCALATE resolution was archived and carried into the next Task Claim

## Interaction with Other Skills

- **`code-review-and-quality`**: B's core review methodology — this skill orchestrates *when* and *how*; that skill defines *what* to review.
- **`doubt-driven-development`**: B uses this for adversarial verification, including verifying cited evidence in DISAGREE responses.
- **`incremental-implementation`**: A builds in thin vertical slices, each passing the quality gate independently.
- **`test-driven-development`**: A writes tests first. B verifies test quality in Layer 3.
- **`planning-and-task-breakdown`**: Produces the todo list for Phase 0. Also used to split oversized changes.
- **`security-and-hardening`**: B activates this for security-sensitive changes.
- **`git-workflow-and-versioning`**: Both agents follow atomic commit practices.

## Changelog

- **v1.4** — Token-efficiency pass: APPROVE verdicts are now concise session outputs — no `handoff-b-to-a` file is written for them; B→A verdict files are written only for REQUEST CHANGES / ESCALATE or on demand. Removed the inline handoff formats from SKILL.md (the `templates/` files are the single source, read on demand). Condensed Overview, Quick Start, Prerequisites, and Git Workflow prose. All other normative rules unchanged.
- **v1.3** — Restructured into three files: SKILL.md (shared protocol), `references/agent-a-playbook.md`, `references/agent-b-playbook.md`. Deduplicated rules that appeared 3-4 times across sections. Added Agent B Context Isolation Self-Check at Phase 3 start. Removed dead See Also links. Fixed frontmatter version (was stuck at 1.1).
- **v1.2** — Added guidance on isolation risks across different vendors' tools. Added factual commit message rule with matching checks in Red Flags and Verification.
- **v1.1** — Added Agent B session-isolation requirement; required independent evidence verification for DISAGREE; Layer 1 failure no longer stops Layer 2/3; added branch-sync step; added diff-size guidance; softened cross-model statistic; added ESCALATE carry-forward; added test-quality check.
- **v1.0** — Initial version.