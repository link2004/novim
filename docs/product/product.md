# Product Brief

Updated: 2026-08-30
Status: `ACCEPTED FOR IMPLEMENTATION`

## Outcome

Create a personal, terminal-first novim derivative that feels like the
VS Code workbench inside a terminal: browse a project lazily, read code, and
inspect local Git diffs through a responsive multi-pane interface.

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
- Show a VS Code-like workbench. Files view has a project tree on the left and
  a source preview on the right. Diff view has three areas: changed files on
  the left, the old file in the middle, and the new file on the right.
- Start the project browser with only immediate visible entries from the
  working directory. Do not recursively scan descendants until a folder is
  expanded; folder expansion/collapse is triggered by double-click and is
  session-only.
- Let each visible pane boundary be resized with the mouse by dragging it
  wider or narrower, with sensible minimum widths.
- Provide a visible settings menu/panel with six built-in themes, beginning
  with Tokyo Night as the default and including Nord, Gruvbox Dark, Catppuccin
  Mocha, One Dark, and Solarized Light.
- Show a key-help section below the settings controls. It must document the
  actual navigation, toggle, refresh, pane, and close shortcuts, including
  that `Esc` closes settings immediately.
- Support local repository browsing and read-only Git inspection without
  sending source code or credentials to a service by default.
- Keep the initial Git surface read-only: status, history, and diff inspection
  are in scope; stage, unstage, commit, push, merge, rebase, and discard are
  out of scope.
- Use the working tree compared with `HEAD` as the initial diff baseline, and
  include untracked files in the review surface.
- Refresh Git status and the selected diff when entering the Diff view. A
  continuous background polling loop is not required for this slice; `r`
  remains the explicit manual refresh command.
- Render text diffs side-by-side with the old content on the left and the new
  content on the right. Removed lines use red styling and added lines use
  green styling. There is no user-selectable unified-diff fallback.
- Persist display settings locally between launches.
- Hide dot-prefixed files and folders by default, with a settings toggle to
  reveal them; no special allowlist is required in the first slice.
- Keep the initial feature set self-contained; no plugin manager or third-party
  Neovim plugin is required for the planned workbench.
- Make every new workflow observable and testable from a local terminal.

## Non-goals and constraints

- Do not attempt to reproduce all of VS Code, an IDE debugger, or a hosted code
  review service in the first milestone.
- Do not add a unified-diff display mode to the initial side-by-side contract.
- Do not add Git mutations, remote operations, AI execution, or credential
  handling without a separate explicit decision.
- Do not modify the installed release under `~/.local/share/novim` as the
  development workflow.
- Do not require users to learn Vim commands for the core editing path.
- Do not introduce plugins merely to implement the first workbench slice.
- Keep upstream attribution and MIT license notices intact.

## Accepted scope decisions

The next workbench milestone is split into three implementation slices:

1. Fast startup with a root-only, lazy project tree and session-only
   double-click expansion.
2. Six built-in themes, settings key help, immediate settings close, and
   reliable mouse resizing.
3. A three-area, read-only side-by-side Git diff with refresh on entry.

Comparing selected branches or historical commits remains future scope and is
not part of this milestone.
