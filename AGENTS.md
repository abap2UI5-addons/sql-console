# AGENTS.md — AI Assistant Guide for abap2UI5 sql-console

> This file follows the cross-tool AGENTS.md convention and is the single
> agent instruction file of this repository — Claude Code reads `AGENTS.md`
> natively, there is no separate `CLAUDE.md`.

## Project Overview

An SQL console in the browser, built with
[abap2UI5](https://github.com/abap2UI5/abap2UI5) — no Eclipse or SAP GUI needed.

**Language:** English — all code, comments, commit messages, PRs, issues and
documentation must be in English.

## Package Structure

| Package | Content |
|---|---|
| `src/abap/` | The app (`z2ui5_sql_cl_*`), Open-SQL query path |
| `src/native/` | Native-SQL/ADBC path (`zcl_2ui5_native_*`, `zcl_association_processor`), derived from [ZTOAD](https://github.com/marianfoo/ztoad) |
| `src/abap/z2ui5_sql_cl_context` | Vendored utility copy — **see below** |
| `src/abap/z2ui5_sql_cl_db` | Vendored persistence copy (reads/writes the shared `z2ui5_t_91`) |

## The Utility Copy Principle

`z2ui5_sql_cl_context` and `z2ui5_sql_cl_db` are **trimmed, renamed copies** of
the abap2UI5 utility classes (`z2ui5_cl_util` / `z2ui5_cl_util_db` in the core),
carrying only the methods this addon uses plus the private helpers those need.
The app calls `z2ui5_sql_cl_context=>…` / `z2ui5_sql_cl_db=>…`, never
`z2ui5_cl_util=>…` directly. This keeps the install dependency-free (abapGit has
no dependency management). The core and the other addons use the same pattern.
When a new utility method is needed, copy it from the core utility class (with
its private helpers) into the context copy rather than adding a dependency.

## Dependencies

Installed alongside via abapGit; declared in the abaplint configs:

* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [custom-controls](https://github.com/abap2UI5-addons/custom-controls) — `z2ui5_cl_cc_spreadsheet`

## Security

This is a developer tool. It runs the SQL the user enters, without an
authorization check of its own; the native path uses ADBC and therefore
bypasses ABAP authorizations and client separation. Before using it beyond a
development system, add your own authorization checks and restrict who may run
the app. See the README Todo — authorization checks and full ABAP Cloud
readiness are still open.

## Coding Style

Follows the abap2UI5 core conventions (see its
[AGENTS.md](https://github.com/abap2UI5/abap2UI5/blob/main/AGENTS.md)): Clean
ABAP with backtick string literals and string templates (`|…{ }…|`). The
`src/native/` classes are ZTOAD-derived and keep their own style
(`errorNamespace` in `abaplint.jsonc` is loosened for them, with `check_syntax`
excludes for their test doubles).

## Validation

Run `npx abaplint` before considering changes complete (config `abaplint.jsonc`,
0 issues expected on the standard config). CI:

* `ABAP_STANDARD` — lint against Standard ABAP
* `ABAP_CLOUD` — lint against ABAP Cloud; the `src/native/` ADBC/DDIC code is
  **not** ABAP-Cloud-ready, so this check has known findings there
* `renaming` (`rename_test.yaml`) — namespace-rename check
* `build_rename` — manual workflow that pushes a namespace-renamed branch
  `rename_<name>` for a parallel install

There is no 702 downport (the native code uses APIs unavailable at 7.02).
All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).
