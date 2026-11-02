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

## The Utility Copies (`src/abap/`)

Utilities are vendored from the [abap-util](https://github.com/abap-util/abap-util)
master catalog instead of being referenced — abapGit has no dependency
management:

| Object | Copy of | How |
|---|---|---|
| `z2ui5_sql_cl_context` | `zabaputil_cl_util_context` | renamed, trimmed to the methods this repository uses plus the helpers they need |
| `z2ui5_sql_cl_db` | `zabaputil_cl_util_db` | renamed, as-is (the key/value store for history and draft) |
| `z2ui5_sql_db` | `zabaputil_t_91` | renamed, as-is (the table of `z2ui5_sql_cl_db`; 12 characters, so the namespace rename stays within 16) |
| `z2ui5_sql_cx_error` | `zabaputil_cx_util_error` | renamed, as-is |

* **Nothing from the core's frozen `src/99/01`.** `z2ui5_cl_util*`,
  `z2ui5_cx_util_error` and `z2ui5_t_91` are kept in abap2UI5 for
  compatibility only. The ajson and S-RTTI classes the context calls
  (`z2ui5_cl_ajson`, `z2ui5_cl_srt_*`) are the core's own and always present.
* **New methods are added locally** to `z2ui5_sql_cl_context`; if abap-util
  already has the method, copy it from there with its private helpers. A
  periodic sync merges local additions back into abap-util.
* The copies are kept as-is so the sync can diff them; where this
  repository's stricter abaplint rules disagree with the master's code, the
  copy is excluded from that rule in `abaplint.jsonc` instead of rewritten.

## Dependencies

Installed alongside via abapGit; declared in the abaplint configs:

* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [custom-controls](https://github.com/abap2UI5-addons/custom-controls) — `z2ui5_cl_cci_spreadsheet`

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

* `publish-702` / `abap-702` — `publish-702` writes the downported `702`
  branch on every push to `main` (`npm run auto_downport` against
  `.github/abaplint/abap_702.jsonc`), and `abap-702` lints it. The branch
  carries `src/abap/` only: the native code uses APIs unavailable at 7.02.
  Never commit to `702` by hand.

All `.abap`/`.xml`/config files are LF-only (`.gitattributes` enforces it).
