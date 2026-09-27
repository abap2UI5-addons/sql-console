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
| `src/abap/` | The app (`z2ui5_sql_cl_*`), Open-SQL query path — Standard ABAP and ABAP Cloud |
| `src/native/` | Native-SQL/ADBC path (`zcl_2ui5_native_*`, `zcl_association_processor`), derived from [ZTOAD](https://github.com/marianfoo/ztoad) — Standard ABAP only |

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
(`errorNamespace` in `abaplint.jsonc` and `.github/abaplint/rename.json` is
loosened for them, with `check_syntax` excludes for their test doubles).

## Validation

Run `npm run check` before considering changes complete: it runs the same steps
as CI, and all of them must pass. CI:

* `abap-standard` — lint against Standard ABAP (`abaplint.jsonc`)
* `abap-cloud` — lint against ABAP Cloud (`.github/abaplint/abap_cloud.jsonc`).
  `src/native/` is excluded there because it is Standard ABAP only by design:
  ABAP Cloud forbids EXEC SQL and does not release ADBC or the DDIC/ADT
  internals the package reads. `src/abap/` must stay ABAP-Cloud-clean.
* `check-abap2ui5` — the abap2UI5-linter over the app classes and their views
  (`abap2ui5lint.jsonc`)
* `check-rename` — namespace-rename check (`.github/abaplint/rename.json`,
  against the 9-character placeholder `zabap2ui5`). It resolves types like
  `abaplint.jsonc` and lints `src/native/` too, but leaves that package out of
  the renamed output: its classes are named outside the z2ui5 namespace, and
  its history table `z2ui5_nsql_c_hst` is already at the 16-character DDIC
  limit, so it cannot take a longer namespace
* `build-rename` — manual workflow that pushes a namespace-renamed branch
  `rename_<name>` for a parallel install; the branch carries `src/abap/` only

There is no 702 downport (the native code uses APIs unavailable at 7.02).
All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).
