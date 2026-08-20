[![ABAP](https://img.shields.io/badge/ABAP-Standard%20%E2%86%92%20Cloud-blue)](#install)
[![namespace](https://img.shields.io/badge/namespace-z2ui5__sql__cl-blue)](abaplint.jsonc)
[![dependency](https://img.shields.io/badge/dependency-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
<br>
[![abap-standard](https://github.com/abap2UI5-addons/sql-console/actions/workflows/abap-standard.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/abap-standard.yaml)
[![abap-cloud](https://github.com/abap2UI5-addons/sql-console/actions/workflows/abap-cloud.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/abap-cloud.yaml)
<br>
[![check-abap2ui5](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-abap2ui5.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-abap2ui5.yaml)
[![check-rename](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-rename.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-rename.yaml)
<br>
[![build-rename](https://github.com/abap2UI5-addons/sql-console/actions/workflows/build-rename.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/build-rename.yaml)
<br>
[![abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Fsql-console%2Fmain%2F.github%2Fbadges%2Fabap2ui5.json)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-abap2ui5.yaml)
[![check-abap2UI5](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fabap2UI5-addons%2Fsql-console%2Fmain%2F.github%2Fbadges%2Fcheck-abap2ui5.json)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/check-abap2ui5.yaml)

# sql-console
SQL Console in Your Browser – No Need for Eclipse or SAP GUI Installation

#### Key Features
* Execute SQL commands
* Save query history
* Data preview

#### Compatibility
* S/4 Public Cloud and BTP ABAP Environment (ABAP for Cloud)
* S/4 Private Cloud or On-Premise (ABAP for Cloud, Standard ABAP)
* SAP NetWeaver AS ABAP 7.50 or higher (Standard ABAP)

#### Security
This is a developer tool. It runs the SQL the user enters, without an authorization check of its own; the native path additionally uses ADBC and therefore bypasses ABAP authorizations and client separation. Before using it beyond a development system, add your own authorization checks and restrict who may run the app (see the Todo below).

#### Dependencies
* [abap2UI5](https://github.com/abap2UI5/abap2UI5)
* [popups](https://github.com/abap2UI5-addons/popups)
* [custom-controls](https://github.com/abap2UI5-addons/custom-controls)

#### Credits
* Logic for Query to ABAP SQL Translation used from [ZTOAD](https://github.com/marianfoo/ztoad), integrated by [choper725](https://github.com/choper725)

#### Todo
* Extend the input-to-SQL translation
* Add authorization checks
* XLSX Export
* Fix ABAP Cloud Readiness

#### Demo
<img width="700" alt="image" src="https://github.com/abap2UI5-addons/sql-console/assets/102328295/0be2bb38-d68a-475c-910a-b341757e5862">

#### Contribution & Support
Pull requests are welcome! Whether you're fixing bugs, adding new functionality, or improving documentation, your contributions are highly appreciated. If you encounter any issues, feel free to open an issue.
