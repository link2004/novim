# Product Brief

Updated: 2026-08-27
Status: `BOOTSTRAPPING`

## Outcome

Create a personal, terminal-first novim derivative that feels like the
VS Code workbench inside a terminal: browse a project, read code, and inspect
local Git diffs through a clear two-pane interface.

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
- Show a VS Code-like workbench with a left project/changed-file pane and a
  right code or diff pane.
- Let the user resize the pane boundary with the mouse by dragging it wider or
  narrower, with sensible minimum widths.
- Provide a visible settings menu/panel for display choices, starting with a
  setting to hide or show dot-prefixed files and folders such as `.vscode`.
- Support local repository browsing and read-only Git inspection without
  sending source code or credentials to a service by default.
- Keep the initial Git surface read-only: status, history, and diff inspection
  are in scope; stage, unstage, commit, push, merge, rebase, and discard are
  out of scope.
- Use the working tree compared with `HEAD` as the initial diff baseline, and
  include untracked files in the review surface.
- Persist display settings locally between launches.
- Hide dot-prefixed files and folders by default, with a settings toggle to
  reveal them; no special allowlist is required in the first slice.
- Keep the initial feature set self-contained; no plugin manager or third-party
  Neovim plugin is required for the planned workbench.
- Make every new workflow observable and testable from a local terminal.

## Non-goals and constraints

- Do not attempt to reproduce all of VS Code, an IDE debugger, or a hosted code
  review service in the first milestone.
- Do not add Git mutations, remote operations, AI execution, or credential
  handling without a separate explicit decision.
- Do not modify the installed release under `~/.local/share/novim` as the
  development workflow.
- Do not require users to learn Vim commands for the core editing path.
- Do not introduce plugins merely to implement the first workbench slice.
- Keep upstream attribution and MIT license notices intact.

## Open product decisions

The initial product decisions are resolved. Comparing selected branches or
historical commits can be considered after the first workbench slice, but is
not part of its initial contract.
