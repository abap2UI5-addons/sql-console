# AGENTS.md — AI Assistant Guide for abap2UI5 sql-console

> This file follows the cross-tool AGENTS.md convention and is the single
> agent instruction file of this repository — `CLAUDE.md` only points here.

## Project Overview

An SQL console in the browser, built with
[abap2UI5](https://github.com/abap2UI5/abap2UI5) — no Eclipse or SAP GUI needed.

**Language:** English — all code, comments, commit messages, PRs, issues and
documentation must be in English.

## Package Structure

| Package | Content |
|---|---|
| `src/abap/` | The app (`z2ui5_cl_sql_*`), Open-SQL query path — Standard ABAP and ABAP Cloud |
| `src/native/` | Native-SQL/ADBC path (`z2ui5_cl_sql_native_*`, `z2ui5_cl_sql_assoc_processor`), derived from [ZTOAD](https://github.com/marianfoo/ztoad) — Standard ABAP only |

## The Utility Copies (`src/abap/`)

Utilities are vendored from the [abap-util](https://github.com/abap-util/abap-util)
master catalog instead of being referenced — abapGit has no dependency
management:

| Object | Copy of | How |
|---|---|---|
| `z2ui5_cl_sql_context` | `zabaputil_cl_util_context` | renamed, trimmed to the methods this repository uses plus the helpers they need |
| `z2ui5_cl_sql_db` | `zabaputil_cl_util_db` | renamed, as-is (the key/value store for history and draft) - except `load_by_id`, left out (`trimmed` in `.github/abap-util.json`): it read any user's row by its id, past the own-rows rule below, and nothing called it |
| `z2ui5_t_33` | `zabaputil_t_91` | renamed, as-is (the table of `z2ui5_cl_sql_db`; 10 characters, so the namespace rename stays within 16) |
| `z2ui5_cx_sql_error` | `zabaputil_cx_util_error` | renamed, as-is |

* **Nothing from the core's frozen `src/99/01`.** `z2ui5_cl_util*`,
  `z2ui5_cx_util_error` and `z2ui5_t_91` are kept in abap2UI5 for
  compatibility only. The ajson and S-RTTI classes the context calls
  (`z2ui5_cl_ajson`, `z2ui5_cl_srt_*`) are the core's own and always present.
* **New methods are added locally** to `z2ui5_cl_sql_context`; if abap-util
  already has the method, copy it from there with its private helpers. A
  periodic sync merges local additions back into abap-util.
* The copies are kept as-is so the sync can diff them; where this
  repository's stricter abaplint rules disagree with the master's code, the
  copy is excluded from that rule in `abaplint.jsonc` instead of rewritten.

`.github/abap-util.json` names the copies and their masters for abap-util's
`sync-check`: with abap-util checked out next to this repository,
`node ../abap-util/.github/scripts/sync-check.mjs --consumer . --report`
lists every method whose body or declaration differs from the master and
every method only this copy has. `commit` is the abap-util commit the copies
match: run the script without `--report` at that commit and it fails on any
difference that is not named under `settled` or `own`. After a refresh, set
`commit` to the commit the copies were taken from.

## Dependencies

Installed alongside via abapGit; declared in the abaplint configs:

* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [layout-management](https://github.com/abap2UI5-addons/layout-management) —
  not used here, but popups' value help and search help popups need it, so it
  is installed before popups
* [popups](https://github.com/abap2UI5-addons/popups)
* [custom-controls](https://github.com/abap2UI5-addons/custom-controls) — `z2ui5_cl_cci_spreadsheet`

## Security

This is a developer tool. It runs the SQL the user enters, without an
authorization check of its own; the native path uses ADBC and therefore
bypasses ABAP authorizations and client separation. Before using it beyond a
development system, add your own authorization checks and restrict who may run
the app. The Open SQL console passes the ABAP Cloud check; a run on a real
ABAP Cloud system is still open (README Todo).

**Shipping without an authorization check is a deliberate decision of the
maintainer (2026-11-17), stated in the README - do not add one and do not
report its absence as a finding.**

The history documents (`z2ui5_t_33` via `z2ui5_cl_sql_history_api`,
`z2ui5_t_32` in the native console) are deserialized into objects, so they
are treated as untrusted input: `z2ui5_cl_sql_history_api` hands out only rows
of the current user whose content names the same user and id, and
`z2ui5_cl_sql_context=>xml_srtti_parse` refuses (raises
`z2ui5_cx_sql_error`) any document that names a class outside S-RTTI
(`xml_srtti_check_classes` - the core's prefix is derived from
`z2ui5_cl_srt_typedescr` by type). Every caller of the parse catches that
exception; a new reader of stored documents must go through the same parse.

## Coding Style

Follows the abap2UI5 core conventions (see its
[AGENTS.md](https://github.com/abap2UI5/abap2UI5/blob/main/AGENTS.md)): Clean
ABAP with backtick string literals and string templates (`|…{ }…|`). The
`src/native/` classes are ZTOAD-derived and keep their own style
(`errorNamespace` in `abaplint.jsonc` is loosened for them, with
`check_syntax` excludes for their test doubles; the namespace rename leaves
`src/native/` out - package.json `config.renameSkip`).

## Validation

Run `npm run check` before considering changes complete: it runs the same steps
as CI, and all of them must pass. CI comes from the shared CI template of
abap2UI5-addons (reusable workflows in
[rap-ext](https://github.com/abap2UI5-addons/rap-ext/blob/main/.github/ci/README.md),
pinned by commit in the `uses:` lines and moved by `bump-deps`); `ci` runs
one job per check:

* abaplint against Standard ABAP (`abaplint.jsonc`)
* abaplint against ABAP Cloud (`.github/abaplint/abap_cloud.jsonc`).
  `src/native/` is excluded there because it is Standard ABAP only by design:
  ABAP Cloud forbids EXEC SQL and does not release ADBC or the DDIC/ADT
  internals the package reads. `src/abap/` must stay ABAP-Cloud-clean.
* `abap2ui5lint` — the abap2UI5-linter over the app classes and their views
  (`abap2ui5lint.jsonc`)
* `npm run check:702` — the 7.02 gate of a pull request:
  `.github/scripts/check-702.sh` downports a scratch copy of `src/` in
  `build/702` and lints it with `.github/abaplint/abap_702.jsonc`, which
  leaves `src/native/` out as the `702` branch does (`src/` itself is never
  rewritten)
* `unit` — the ABAP Unit tests on abap2UI5's transpiled Node runtime, the way abap2UI5 tests itself: `npm run unit` (`.github/scripts/unit.mjs`) copies the packages into a checkout of abap2UI5's `main` (abap2UI5-ext, layout-management, popups and custom-controls beside it; `src/native` stays out - its ADT classes are on-premise only), downports, transpiles and runs the tests of this repository's classes
* `rename` — namespace-rename check (`.github/abaplint/rename.json`,
  against the 9-character placeholder `zabap2ui5`). It resolves types like
  `abaplint.jsonc` and lints `src/native/` too, but leaves that package out of
  the renamed output: `z2ui5_cl_sql_native_console_st` is already at the
  30-character class limit, so it cannot take a longer namespace

The other workflows:

* `build-rename` — manual workflow that pushes a namespace-renamed branch
  `rename_<name>` for a parallel install; the branch carries `src/abap/` only.
  This repository's own: the template's runs `rename.mjs`, which this
  repository does not have
* `ci-702` — writes the downported `702` branch on every push to `main`
  (`npm run auto_downport` against `.github/abaplint/abap_702.jsonc`) and
  lints it. The branch carries `src/abap/` only: the native code uses APIs
  unavailable at 7.02. Never commit to `702` by hand.

The sibling addons (popups, custom-controls, and layout-management for the
unit run) are resolved at the commit `.github/deps.json` pins, in CI and in
`npm run unit`; `bump-deps` moves the pins monthly, and the weekly `ci` run
checks their `main` tips. A local `npm run check` clones their `main`. The
702 config gives popups' `702` branch a folder of its own (`/popups-702`).

All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).
