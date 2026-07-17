# Repository Guidelines

## Project Structure & Module Organization

This repository is the Org-mode index and note layer for a broader learning workspace. Keep global navigation and current priorities in `00-index/`; use `00-quick/` for short notes, `10-courses/` for course-driven material, `20-topics/` for long-lived technical subjects, `40-resources/` for coarse resource maps, and `90-archive/` for paused or completed material. Each active subject should have one `index.org` entry point, with optional `plan.org`, `notes/`, or `addons/` files when needed. Learning code and runnable projects belong in the sibling `../projects/` directory, not here. Treat `public-html/` as generated output unless a task explicitly concerns exports.

## Build, Test, and Development Commands

There is no repository-wide build or application runtime. Use lightweight checks after editing:

- `rg --files -g '*.org'` lists tracked learning documents.
- `git diff --check` detects whitespace errors in pending changes.
- `emacs --batch --quick FILE.org --eval '(progn (org-mode) (check-parens))'` checks one Org file for structural delimiter errors.
- `git status --short` confirms the intended change set before committing.

Run language-specific builds and tests inside the corresponding directory under `../projects/`.

## Writing Style & Naming Conventions

Write concise, structured Org documents. Start new pages with `#+title:`, use `*`, `**`, and `***` headings consistently, and prefer relative Org links such as `[[file:../20-topics/cpp/index.org][C++]]`. Keep index pages navigational; place detailed explanations in subject notes. Follow the surrounding directory's naming style, generally lowercase descriptive names such as `index.org`, `plan.org`, or `chapter3_2_variants.org`. Do not reformat unrelated notes.

## Testing Guidelines

No automated test framework or coverage target exists for this note repository. Validate edited Org syntax, confirm every new local link resolves from the file containing it, and inspect the rendered table alignment when changing Org tables. For project code, follow that project's own test configuration.

## Commit & Pull Request Guidelines

History uses short, scoped subjects such as `update index` and `cpp primer: finish chapter 10 & chapter 11`. Prefer an imperative, focused summary: `ocaml: add chapter 3 resume point`. Keep one logical documentation change per commit. Pull requests should explain the learning area affected, list moved or newly linked files, and mention validation performed. Add screenshots only when exported HTML or visual layout changes.

## Security & Configuration

Never commit `.env*`, private keys, certificates, editor state, or machine-specific shell configuration. Preserve unrelated local and untracked files when updating indexes.
