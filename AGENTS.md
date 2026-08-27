# Repository Agent Rules

This file is the repository-local operating contract for Codex and other
agents. Read it before changing code or durable project records.

## Project workflow

- Read `docs/repository.md`, `project-state.md`, the canonical current task,
  backlog and latest review before implementation or review.
- Keep exactly one actionable task at the current-task path recorded in
  `docs/repository.md`.
- Implement one task on its recorded isolated branch. Do not implement directly
  on the default or protected branch.
- Use `$stateless-implementer` for the implementation handoff and
  `$project-orchestrator` for planning, review, delivery and task advancement.
- Preserve unrelated working-tree changes, secrets, private data and existing
  product contracts.

## Documentation structure

- Product decisions normally live in `docs/product/`.
- Architecture and contracts normally live in `docs/architecture.md` and
  `docs/architecture/`.
- Durable decisions normally live in `docs/adr/`.
- Work state normally lives in `project-state.md`, `docs/tasks/` and
  `docs/reviews/`.
- Record equivalent paths in `docs/repository.md` instead of creating a second
  documentation tree.

## Completion

A task is complete only when its acceptance criteria and relevant local
validation pass, the review outcome is recorded, and the delivery policy in
`docs/repository.md` has been followed. Local evidence must not be described as
hosted, production, recovery or customer-acceptance evidence.
