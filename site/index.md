---
layout: home

hero:
  name: "SQL Console"
  text: "Type a query, see the result as a table, keep the history."
  image:
    src: /logo.svg
    alt: abap2UI5 addons
  actions:
    - theme: brand
      text: Get started
      link: /guide
    - theme: alt
      text: GitHub
      link: https://github.com/abap2UI5-addons/sql-console
    - theme: alt
      text: All addons
      link: https://abap2ui5-addons.github.io/

features:
  - title: "ABAP SQL console (z2ui5_cl_sql_app_01) with Max Rows and a result table"
  - title: "Native SQL console via ADBC (z2ui5_cl_sql_native_console) on Standard ABAP"
  - title: "Search, range filter and spreadsheet export of the result"
  - title: "Per-user query history to reload or clear queries and results"
  - title: "Association path expressions mapped to joins in the native console"
---

## What it does

sql-console is an abap2UI5 app that runs an SQL query entered in the browser and shows the result as a table with search, filter, spreadsheet export and a per-user query history. The Open SQL console (src/abap) is ABAP-Cloud-clean; the native SQL console (src/native) runs statements through ADBC on Standard ABAP. Use it when you want a quick look at the data of a system without starting Eclipse or SAP GUI. It is a developer tool without authorization checks of its own, so read the Security section before using it beyond a development system.

## Requirements

- abap2UI5
- abap2UI5-addons/popups
- abap2UI5-addons/custom-controls (spreadsheet export, z2ui5_cl_cci_spreadsheet)
- ABAP Cloud or Standard ABAP on NetWeaver 7.50 or higher
- NetWeaver 7.02 - 7.40: the downported branch 702, with the Open SQL console only
- Native SQL console (ADBC) needs Standard ABAP; on ABAP Cloud use the Open SQL console

## Installation

With [abapGit](https://abapgit.org), from [the repository](https://github.com/abap2UI5-addons/sql-console):

- Install with abapGit in this order: 1. abap2UI5, 2. popups, 3. custom-controls, 4. this repository (branch main)
- Start with ?app_start=z2ui5_cl_sql_app_01 (Open SQL) or ?app_start=z2ui5_cl_sql_native_console (native, Standard ABAP only)
- Add your own authorization checks before using it beyond a development system

The [Guide](/guide) has every step.

## A first app

```abap
?app_start=z2ui5_cl_sql_app_01
```

## Links

- [abap2UI5-addons/popups](https://github.com/abap2UI5-addons/popups)
- [abap2UI5-addons/custom-controls](https://github.com/abap2UI5-addons/custom-controls)
- [ZTOAD (query translation credits)](https://github.com/marianfoo/ztoad)
- [abap2UI5](https://github.com/abap2UI5/abap2UI5)
- [The repository](https://github.com/abap2UI5-addons/sql-console) - issues and pull requests welcome
