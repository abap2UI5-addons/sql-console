[![ABAP_STANDARD](https://github.com/abap2UI5-addons/sql-console/actions/workflows/ABAP_STANDARD.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/ABAP_STANDARD.yaml)
[![ABAP_CLOUD](https://github.com/abap2UI5-addons/sql-console/actions/workflows/ABAP_CLOUD.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/ABAP_CLOUD.yaml)
<br>
[![rename_test](https://github.com/abap2UI5-addons/sql-console/actions/workflows/rename_test.yaml/badge.svg)](https://github.com/abap2UI5-addons/sql-console/actions/workflows/rename_test.yaml)

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
Pull Requests are welcome! Whether you're fixing a bug, adding new functionality, or improving the documentation, your contributions are always appreciated. If you run into problems, feel free to open an issue.
