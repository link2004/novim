# Product Brief

Updated: 2026-08-27
Status: `BOOTSTRAPPING`

## Outcome

Create a personal, terminal-first novim derivative that keeps novim's
VS Code-like editing ergonomics while adding focused workflows for browsing
projects, inspecting code, and reviewing local Git changes.

The derivative must be runnable through a separate command so experimentation
cannot overwrite the installed upstream `novim` configuration or the user's
personal Neovim configuration.

## Users and problem

- Primary users: terminal-first developers who want a friendly editor without
  learning Vim modes.
- Problem: the current novim experience is pleasant for basic editing, but
  some repository navigation, code-review, and project-specific workflows need
  a more deliberate interface.

## Required behavior

- Preserve the existing novim-friendly editing model and standard shortcuts
  unless a task explicitly changes them.
- Launch through an independent development command, provisionally named
  `novim-dev`.
- Keep development configuration, writable runtime data, and state isolated
  from installed upstream `novim` and the user's normal Neovim configuration.
- Support local repository browsing and Git inspection without sending source
  code or credentials to a service by default.
- Make every new workflow observable and testable from a local terminal.

## Non-goals and constraints

- Do not attempt to reproduce all of VS Code, an IDE debugger, or a hosted code
  review service in the first milestone.
- Do not add automatic push, remote mutation, AI execution, or credential
  handling without a separate explicit decision.
- Do not modify the installed release under `~/.local/share/novim` as the
  development workflow.
- Do not require users to learn Vim commands for the core editing path.
- Keep upstream attribution and MIT license notices intact.

## Open product decisions

These decisions are intentionally left for the first grill because they change
the task order or the safety boundary:

1. First high-value workflow: repository/code navigation, Git diff review, or
   ordinary editing ergonomics.
2. Git authority: read-only inspection, local stage/unstage and commit, or a
   broader workflow that also includes push and remote operations.
3. Extension policy: preserve a small self-contained config, or accept a
   plugin-backed architecture for richer search, LSP, and diff views.
