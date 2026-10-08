# sql-console

[![abap2UI5-addons](https://img.shields.io/badge/abap2UI5--addons-app-1873b4)](https://github.com/abap2UI5-addons)
[![ABAP](https://img.shields.io/badge/ABAP-Cloud%20%7C%20Standard%20%E2%89%A5%207.50-blue)](#installation)
[![abap2UI5](https://img.shields.io/badge/requires-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![popups](https://img.shields.io/badge/requires-popups-blue)](https://github.com/abap2UI5-addons/popups)
[![custom-controls](https://img.shields.io/badge/requires-custom--controls-blue)](https://github.com/abap2UI5-addons/custom-controls)
[![License](https://img.shields.io/github/license/abap2UI5-addons/sql-console)](LICENSE)
<br>
[![ABAP Cloud](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sql-console/abap-cloud.yaml?branch=main&label=ABAP%20Cloud)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/abap-cloud.yaml)
[![ABAP Standard](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sql-console/abap-standard.yaml?branch=main&label=ABAP%20Standard)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/abap-standard.yaml)
[![rename](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sql-console/check-rename.yaml?branch=main&label=rename)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-rename.yaml)
[![check-abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Fsql-console%2Fbadges%2Fcheck-abap2ui5.json)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-abap2ui5.yaml)
[![abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Fsql-console%2Fbadges%2Fabap2ui5.json)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-abap2ui5.yaml)

**An SQL console in your browser - no Eclipse or SAP GUI installation
needed.** Type a query, run it and look at the result as a table, with search,
filter, export and a per-user query history. Built with abap2UI5, for ABAP
developers who want a quick look at the data of a system, on ABAP Cloud as
well as on Standard ABAP.

> Part of [abap2UI5-addons](https://github.com/abap2UI5-addons) - addons and apps for [abap2UI5](https://github.com/abap2UI5/abap2UI5), installed with [abapGit](https://abapgit.org).

<img width="700" alt="image" src="https://github.com/abap2UI5-addons/sql-console/assets/102328295/0be2bb38-d68a-475c-910a-b341757e5862">

## Why

A quick query should not need a development environment. The SQL console of
ADT needs Eclipse, the classic tools need SAP GUI - and on ABAP Cloud there
is no SAP GUI at all. sql-console runs the query in any browser that can reach
the system, as an abap2UI5 app.

Good for:

- **ABAP developers** who want to check data without starting Eclipse or SAP GUI.
- **ABAP Cloud systems** - the Open SQL console (`src/abap`) is ABAP-Cloud-clean.
- **Native SQL on Standard ABAP** - the native console (`src/native`) runs the
  statement through ADBC.

It is a developer tool, not an end-user app - read [Security](#security)
before you use it beyond a development system.

## Installation

**Requirements**

- ABAP Cloud (S/4 Public Cloud, BTP ABAP Environment, S/4 Private Cloud or
  On-Premise with ABAP for Cloud) or Standard ABAP on SAP NetWeaver AS ABAP
  7.50 or higher. The native SQL console (`src/native`, ADBC) needs Standard
  ABAP; on ABAP Cloud, use the Open SQL console (`src/abap`).
- [abap2UI5](https://github.com/abap2UI5/abap2UI5)
- [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups)
- [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls) -
  the spreadsheet export (`z2ui5_cl_cci_spreadsheet`)

**Steps** - with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5)
2. [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups)
3. [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
4. this repository (branch `main`)

**Start** - like any abap2UI5 app:

| App | Class | Start |
|---|---|---|
| ABAP SQL Console (Open SQL) | `z2ui5_sql_cl_app_01` | `?app_start=z2ui5_sql_cl_app_01` |
| Native SQL Console (ADBC, Standard ABAP only) | `zcl_2ui5_native_sql_console` | `?app_start=zcl_2ui5_native_sql_console` |

## Usage

**ABAP SQL Console** (`z2ui5_sql_cl_app_01`, package `src/abap`)

1. Type an ABAP SQL query into the editor - it starts with `Select * from T100`.
2. Set **Max Rows** (default 500) and press **Run**.
3. The result comes up as a table: search it, filter it with a range popup and
   export it with the spreadsheet button.
4. Every query goes into your history. Select an entry to load the query and
   its result again, or clear the history.

**Native SQL Console** (`zcl_2ui5_native_sql_console`, package `src/native`)

The same idea for native SQL: the statement runs through ADBC, with a
**Fallback Limit** (default 100) added when the statement has no limit of its
own, a data preview and a query history (table
`Z2UI5_NSQL_C_HST`) whose entries you load again or delete. Association path
expressions in the statement are mapped to joins (`zcl_association_processor`).

## Features

* Execute SQL commands
* Save query history
* Data preview

## Security

This is a developer tool. It runs the SQL the user enters, without an authorization check of its own; the native path additionally uses ADBC and therefore bypasses ABAP authorizations and client separation. Before using it beyond a development system, add your own authorization checks and restrict who may run the app (see the Todo below).

## Todo

* Extend the input-to-SQL translation
* Add authorization checks
* XLSX Export
* Fix ABAP Cloud Readiness

## Development

```sh
npm ci
npm run check   # abaplint Standard + ABAP Cloud, abap2UI5-linter, rename check
```

`npm run check` runs the same steps as CI. The manual `build-rename` workflow
pushes a namespace-renamed copy to a branch `rename_<name>` for a parallel
installation.

## Contributing

Issues and pull requests are welcome - whether you're fixing bugs, adding new
functionality, or improving documentation. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT - see [LICENSE](LICENSE).

Credits: logic for query to ABAP SQL translation used from
[ZTOAD](https://github.com/marianfoo/ztoad), integrated by
[choper725](https://github.com/choper725).
