---
name: dual-agent-pair-programming
description: Orchestrates two AI agents in a structured pair programming workflow — Agent A (Senior Engineer) implements tasks per spec, Agent B (Tech Lead / Reviewer) reviews for correctness, completeness, and spec compliance. Use when implementing features that touch multiple files, involve core business logic, or require high correctness guarantees. Ensures coding stays aligned with PRD and todo list through adversarial review cycles with standardized handoff protocols. 触发词：结对编程、双agent编程、双agent结对编程、AI结对、双人编程审查、agent协作开发、对抗式代码审查。
version: 1.3
---

# Dual AI Agent Pair Programming

## Overview

Single AI agent development suffers from hallucination, laziness, and spec drift — the agent confidently writes plausible code that doesn't match the actual requirements. Human code review catches these issues but is slow and expensive.

This skill solves both problems by orchestrating two AI agents in a structured adversarial collaboration:

- **Agent A (Senior Engineer)** — implements tasks strictly following the PRD, spec docs, and todo list
- **Agent B (Tech Lead / Reviewer)** — reviews Agent A's work for spec compliance, correctness, and completeness; may propose minimal fixes or improvements

The two agents operate in alternating review cycles with a standardized handoff protocol, ensuring no task is marked done without independent verification. The goal is singular: **ensure the implementation faithfully matches the spec with no omissions**.

```
┌─────────────┐     Handoff A→B      ┌─────────────┐
│  Agent A    │ ────────────────────▶ │  Agent B    │
│  (Engineer) │                       │  (Reviewer) │
│             │ ◀──────────────────── │             │
└─────────────┘     Handoff B→A      └─────────────┘
       │                                     │
       ▼                                     ▼
  Implement → Test → Commit          Review → Verdict → Fix/Feedback
       │                                     │
       └──── Quality Gate (lint/type/test/build) ────┘
```

**A note on why this works — and why it can silently fail:** the value of dual-agent review comes entirely from Agent B's *independence*. If Agent B's judgment is contaminated by Agent A's reasoning, or if Agent B accepts Agent A's claims at face value, the whole workflow degrades into an expensive rubber stamp. Every rule below that mentions "independently" or "verify" exists to protect that independence — treat those rules as non-negotiable, not as bureaucratic overhead.

> **Role-specific details** are in separate playbooks to keep each agent's session focused:
> - Agent A: see `references/agent-a-playbook.md`
> - Agent B: see `references/agent-b-playbook.md`

## Quick Start

Three steps to start a dual-agent session:

1. **Open Agent A session** and say:
   ```
   Activate `dual-agent-pair-programming` skill. I am Agent A (Engineer).
   My tool: [Claude Code / Cursor / etc.]. Agent B will use: [Gemini CLI / etc.].
   Spec docs: [paths]. Todo list: [path]. Begin Phase 0.
   ```
2. **When Agent A outputs a handoff**, open a **new, clean Agent B session** (no shared history with Agent A — see Prerequisites §5) and say:
   ```
   Activate `dual-agent-pair-programming` skill. I am Agent B (Reviewer).
   Please review per Phase 3. [paste handoff]
   ```
3. **When Agent B outputs a verdict**, copy it back to Agent A. Repeat until **APPROVE** or **ESCALATE**.

> **Tip:** Use `templates/handoff-a-to-b.md` and `templates/handoff-b-to-a.md` for structured handoff documents.

## Prerequisites — Read Before Use

> **⚠️ Before activating this skill, you MUST complete the following setup.**

### 1. Declare Your Agent Tools

This skill is tool-agnostic. Agent A and B can be any AI coding tool (Claude Code, Cursor, Gemini CLI, Antigravity, Codex, Copilot, etc.). You MUST declare which tool each agent uses **before starting**.

Example declaration:
```
Agent A (Engineer): Claude Code (claude-opus-5)
Agent B (Reviewer): Gemini CLI (gemini-3.6-flash)
```

**Strong recommendation:** Use **different models or tools** for A and B. Same-model agents share blind spots — they were trained on similar data with similar biases, so a mistake Agent A doesn't notice is disproportionately likely to be a mistake Agent B also doesn't notice. Cross-model pairing (e.g., Claude + Gemini, or GPT + Claude) surfaces a meaningfully different set of issues.

> *(This skill does not have controlled measurements of exactly how much cross-model pairing helps — treat it as a strong, well-motivated heuristic rather than a precise statistic, and don't cite a specific percentage as if it were measured.)*

### 2. Ensure Spec Documents Exist

Both agents require these artifacts to be prepared before development starts:

- [ ] **PRD** — Product Requirements Document (e.g., `docs/PRD.md`)
- [ ] **Architecture docs** — system design, data model, tech stack (e.g., `docs/architecture/`)
- [ ] **API specs** — endpoint definitions, request/response schemas
- [ ] **DDL / Data Model** — database schema definitions
- [ ] **Todo list** — task breakdown with acceptance criteria (can be in a plan.md, task.md, or issue tracker)

### 3. Baseline Context Loading

Both agents MUST load the following before starting any work:

```
BASELINE CONTEXT (both agents load at session start):
1. AGENTS.md / CLAUDE.md / GEMINI.md — project behavioral constraints
2. README.md — project overview and setup
3. package.json / go.mod / Cargo.toml — dependencies and scripts
4. docs/PRD.md — product requirements (index; load sub-docs as needed)
5. Architecture docs relevant to current task
6. Current branch, git status, and recent commits
7. The active todo list / task plan
```

**Rule:** Do NOT overwrite or lose existing changes. Check `git status` and `git stash` if needed before starting.

### 4. Install and Activate Agent-Skills

This skill works best when combined with skills from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills). Ensure they are installed and available to both agents (see the agent-skills README for installation instructions per tool).

Each agent should activate specific skills at specific phases — see the Skill Activation Maps in each agent's playbook (`references/agent-a-playbook.md`, `references/agent-b-playbook.md`).

### 5. Session Isolation for Agent B (独立性隔离) — Critical

Agent B's entire value comes from being an *independent* check on Agent A. This independence is easy to lose by accident:

- **Agent B's session MUST be started fresh**, with no shared conversation history, memory, or context from Agent A's session.
- Agent B's context MUST be limited to: the spec documents, the actual code / git diff, and the handoff document. It must **not** see Agent A's chain of reasoning, internal notes, or how Agent A talked itself into a decision — only the artifacts Agent A produced.
- If your tooling makes it easy to accidentally reuse a session (e.g., the same terminal/IDE window, a shared memory feature), explicitly confirm isolation before Phase 3 begins.
- This applies on every review cycle, not just the first.

**Rule of thumb:** if Agent B can explain *why* Agent A made a decision without that explanation appearing in the handoff document itself, isolation has been broken.

**Isolation can still leak even across different vendors' tools:**
- **The human copy-pasting more than the handoff.** Only paste the structured handoff document — never Agent A's full chat transcript or reasoning log.
- **Git history itself.** If Agent A's commit messages contain argumentative reasoning ("chose X because I think Y is better here..."), that reasoning reaches Agent B through `git log`. This is why commit messages must stay factual (see `references/agent-a-playbook.md`, Phase 1).

> Agent B also performs a **Context Isolation Self-Check** at the start of Phase 3 — see `references/agent-b-playbook.md`.

### 6. Authorization Boundaries (授权边界)

| Boundary Level | Category & Operations | Action / Behavior |
|----------------|------------------------|-------------------|
| **Always Allow** (预授权) | • Reading project files & documentation<br>• Editing files explicitly within task scope<br>• Creating or updating unit/integration tests<br>• Running quality gate commands (`lint`, `typecheck`, `test`, `build`)<br>• `git status`, `git diff`, `git add`, `git commit` on the current branch | Agents execute autonomously without prompting the user. |
| **Ask First** (需审批) | • Database schema changes (DDL / migrations)<br>• Adding or updating external package dependencies<br>• Modifying system configuration files or CI/CD pipelines<br>• Editing files outside the specified task scope<br>• Switching, creating, or merging Git branches | Agent MUST stop, present options/tradeoffs, and wait for human confirmation. |
| **Never** (绝对禁止) | • Committing secrets, API keys, or credentials<br>• Deleting existing passing unit or integration tests<br>• Directly editing environment secret files (`.env`)<br>• Interacting with or deploying directly to production environments<br>• Skipping quality gate verification checks | Strictly prohibited. Agents MUST NOT perform or ask to perform these actions. |

## When to Use

**Activate this skill when:**
- The task touches more than 1 file
- The change involves core business logic, financial calculations, or security-sensitive code
- Database schema changes are involved
- The task has complex acceptance criteria
- You want high confidence that the implementation matches the spec
- History shows the AI agent has been drifting from requirements

**Do NOT use when:**
- Single-file, single-function trivial changes
- Pure formatting, comment, or documentation changes
- Mechanical refactors (rename, move) where correctness is obvious
- The cost of the review cycle exceeds the risk of the change

**Keep each handoff review-sized.** If a single change pushes past a few hundred lines of diff or touches many unrelated files, use `planning-and-task-breakdown` to split it into smaller sub-tasks, each going through its own Phase 0→6 cycle.

## The Workflow

```
Dual-Agent Cycle:
- [ ] Phase 0: Task Selection — Agent A claims a task (see agent-a-playbook)
- [ ] Phase 1: Implementation — Agent A codes, tests, commits (see agent-a-playbook)
- [ ] Phase 2: Handoff A→B — Agent A produces structured handoff document
- [ ] Phase 3: Review — Agent B performs three-layer review (see agent-b-playbook)
- [ ] Phase 4: Handoff B→A — Agent B produces review verdict
- [ ] Phase 5: Response — Agent A addresses findings (see agent-a-playbook)
- [ ] Phase 6: Convergence — APPROVE, or loop back to Phase 2 (max 3 cycles)
```

### Handoff A → B Format

Use `templates/handoff-a-to-b.md` or the inline format:

```markdown
## Handoff: Agent A → Agent B

### Task Summary
- **Task ID:** [ID from todo list]
- **Task Title:** [description]
- **Branch:** [branch name]
- **Commits:** [list of commit SHAs with one-line summaries]
- **Review Cycle:** [1st / 2nd / 3rd]

### What Was Implemented
[2-5 sentences describing what was done and key decisions made]

### Acceptance Criteria Status
- [x] Criteria 1: [description] — implemented in [file:line]
- [x] Criteria 2: [description] — implemented in [file:line]
- [ ] Criteria 3: [description] — NOT implemented, reason: [explain]

### Files Changed
| File | Change Type | Description |
|------|------------|-------------|
| `src/xxx.ts` | Modified | Added validation logic for... |
| `src/xxx.test.ts` | New | Unit tests for... |

### Quality Gate Results
- Lint: ✅ PASS
- Type Check: ✅ PASS
- Tests: ✅ PASS (X passed, 0 failed)
- Build: ✅ PASS

### Review Focus Areas
[List 2-3 areas where Agent B should pay extra attention]

### Assumptions Made
[List any assumptions Agent A made during implementation]

### Spec References
- PRD section: [link]
- API spec: [link]
- Data model: [link]
```

### Handoff B → A Format

Use `templates/handoff-b-to-a.md` or the inline format:

```markdown
## Handoff: Agent B → Agent A

### Review Verdict: APPROVE / REQUEST CHANGES / ESCALATE TO HUMAN

### Task: [Task ID] — [Title]
- **Branch:** [branch name]
- **Commits Reviewed:** [list of SHAs]
- **Review Cycle:** [1st / 2nd / 3rd]

### Spec Compliance (Layer 1)
[PASS / FAIL — with details on any gaps]

### Findings (Layer 2 + Layer 3)

#### Critical (must fix before approve)
1. [File:line] [Description + recommended fix]

#### Important (should fix)
1. [File:line] [Description + recommended fix]

#### Suggestions (optional improvements)
1. [File:line] [Description]

### What's Done Well
[At least one specific positive observation]

### Quality Gate (independently verified by Agent B)
- Lint: ✅/❌
- Type Check: ✅/❌
- Tests: ✅/❌ (X passed, Y failed)
- Build: ✅/❌

### Next Action
- [ ] **APPROVE:** Agent A may mark the task as done ✅
- [ ] **REQUEST CHANGES:** Agent A must sync branch, then address findings and re-submit
- [ ] **ESCALATE:** Needs human decision on: [describe the disagreement]
```

### Phase 6: Convergence

| Condition | Action |
|-----------|--------|
| Agent B issues **APPROVE** | Task is done ✅. Agent A marks it complete in the todo list. |
| **3 review cycles** completed without APPROVE | **ESCALATE to human.** The disagreement is information, not a reason to keep looping. |
| Agent A and B agree to **ESCALATE** | Human reviews the disagreement and makes the call. |

**Anti-pattern:** Do NOT loop more than 3 times. If you're still disagreeing after 3 rounds, the spec is likely ambiguous — that requires human clarification, not more agent rounds.

**After a human resolves an ESCALATE:** record the decision in the handoff archive and carry it forward into the next Phase 0 Task Claim. Do not assume either agent's next session will "remember" the resolution.

### Handoff Archive (Optional)

```
.pair-review/
├── task-{id}/
│   ├── handoff-a-to-b-r1.md    # round 1
│   ├── handoff-b-to-a-r1.md
│   ├── handoff-a-to-b-r2.md    # round 2 (if needed)
│   └── handoff-b-to-a-r2.md
```

- Use a dotfile directory (`.pair-review/`) to keep review artifacts separate from product docs
- Add `.pair-review/` to `.gitignore` if you don't want review history in version control
- Human decisions on ESCALATE'd tasks should always be archived here — they're the one thing a fresh session cannot reconstruct

## Git Workflow

Both Agent A and Agent B operate on the **current working branch** managed by the human user. Branch operations are controlled manually by the user.

```
current-branch (managed by user)
  ├── commit: "feat: implement X"                [Agent A]
  ├── commit: "test: add tests for X"            [Agent A]
  ├── commit: "[reviewer-fix] fix edge case Y"   [Agent B, if applicable]
  └── commit: "fix: address review findings #2"  [Agent A, after review]
```

**Rules:**
- Branch creation, switching, and merging are controlled by the human user (or approved under Ask First)
- Agent B's direct minimal fixes are tagged with `[reviewer-fix]` in commit messages
- Tasks are marked complete only after Agent B issues APPROVE
- Both agents must inspect `git status` before starting any work
- Agent A must re-sync (`git pull` / `git log`) before Phase 5, in case Agent B committed `[reviewer-fix]` changes
- Both agents MUST NOT overwrite, discard, or reset uncommitted changes without explicit human instruction

## Common Rationalizations

| Rationalization | Why it's wrong | Correct Action |
|---|---|---|
| "Agent B is just slowing us down" | Without independent review, spec drift compounds silently. | Complete the full handoff cycle. Skip only when the task meets "Do NOT use" criteria. |
| "I'll skip the handoff template" | Unstructured handoffs waste tokens. The template is the protocol. | Use `templates/handoff-a-to-b.md` and fill in every field. |
| "Both agents agree, so it must be correct" | Same-model agents share blind spots. Agreement proves consistency, not correctness. | Use different models. Schedule periodic human spot-checks. |
| "The tests pass, so Agent B can just approve" | Tests don't catch spec drift, missing features, or architectural problems. | Agent B completes all three review layers regardless of test results. |
| "Agent B should rewrite Agent A's code" | Agent B's role is review, not reimplementation. | B issues REQUEST CHANGES. Direct fixes limited to obvious bugs <10 lines (see agent-b-playbook). |
| "We've been going back and forth too long" | If 3 rounds can't converge, the spec is ambiguous. | Issue ESCALATE TO HUMAN. Wait for human decision. |
| "This change is too small for review" | "Small" changes to core business logic still warrant review. | Check "When to Use" criteria. If core logic is involved, run the full cycle. |
| "Same model is fine" | Same-model pairs share training biases and blind spots. | Declare different tools/models in Prerequisites §1. |
| "The evidence Agent A cited sounds right" | LLMs can produce plausible citations to things that don't exist or don't say what's claimed. | Agent B opens the cited file/section itself (see agent-b-playbook, Re-submission). |
| "Agent B can reuse Agent A's context, saves tokens" | If B sees A's reasoning, B inherits A's framing and blind spots. | Start Agent B in a fresh, isolated session (see Prerequisites §5). |

## Red Flags

- Agent A skipping tests ("I'll add them in the next commit")
- Agent B rubber-stamping with "LGTM" without evidence of actual review
- Handoff documents that omit the acceptance criteria status
- More than 3 review cycles without escalation to human
- Both agents using the same model and same tool
- Quality gate skipped "because it's a small change"
- Agent A marking a task as done before Agent B's APPROVE
- Handoff delivered informally ("just look at the latest commit") instead of via the structured template
- Agent B's session having visibility into Agent A's reasoning/chat history
- Commit messages that argue for a decision instead of factually describing the change
- A single handoff covering a diff too large for a real review
- Review that only checks code quality (Layer 2) while skipping spec compliance (Layer 1)
- A resolved ESCALATE decision not written down anywhere

## Verification

After completing a task via this workflow:

- [ ] Agent A implemented against the spec's acceptance criteria
- [ ] Agent A passed the quality gate before handoff
- [ ] Handoff A→B followed the structured template with all required fields
- [ ] Agent B's session was isolated from Agent A's reasoning/chat history
- [ ] Agent B performed all three review layers, even when Layer 1 failed
- [ ] Agent B independently ran the quality gate
- [ ] Handoff B→A included a clear verdict with categorized findings
- [ ] All Critical findings were resolved before APPROVE
- [ ] Agent A synced the branch before responding to review
- [ ] Convergence reached within ≤ 3 cycles (or escalated to human)
- [ ] The task was marked done only after APPROVE
- [ ] Different models/tools were used for Agent A and Agent B (strongly recommended)
- [ ] Any ESCALATE resolution was archived and carried into the next Task Claim

## Interaction with Other Skills

- **`code-review-and-quality`**: Agent B's core review methodology. This skill orchestrates *when* and *how*; that skill defines *what* to review.
- **`doubt-driven-development`**: Agent B uses this for adversarial verification, including verifying cited evidence in DISAGREE responses.
- **`incremental-implementation`**: Agent A builds in thin vertical slices, each passing the quality gate independently.
- **`test-driven-development`**: Agent A writes tests first. Agent B verifies test quality in Layer 3.
- **`planning-and-task-breakdown`**: Produces the todo list for Phase 0. Also used to split oversized changes.
- **`security-and-hardening`**: Agent B activates this for security-sensitive changes.
- **`git-workflow-and-versioning`**: Both agents follow atomic commit practices.

## Changelog

- **v1.3** — Restructured into three files: SKILL.md (shared protocol), `references/agent-a-playbook.md`, `references/agent-b-playbook.md`. Deduplicated rules that appeared 3-4 times across sections. Added Agent B Context Isolation Self-Check at Phase 3 start. Removed dead See Also links. Fixed frontmatter version (was stuck at 1.1).
- **v1.2** — Added guidance on isolation risks across different vendors' tools. Added factual commit message rule with matching checks in Red Flags and Verification.
- **v1.1** — Added Agent B session-isolation requirement; required independent evidence verification for DISAGREE; Layer 1 failure no longer stops Layer 2/3; added branch-sync step; added diff-size guidance; softened cross-model statistic; added ESCALATE carry-forward; added test-quality check.
- **v1.0** — Initial version.