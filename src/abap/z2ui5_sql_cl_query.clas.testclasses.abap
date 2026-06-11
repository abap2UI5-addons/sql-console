CLASS ltcl_parser DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS normalize_multiline FOR TESTING RAISING cx_static_check.
    METHODS parse_simple FOR TESTING RAISING cx_static_check.
    METHODS parse_all_clauses FOR TESTING RAISING cx_static_check.
    METHODS parse_single FOR TESTING RAISING cx_static_check.
    METHODS parse_distinct FOR TESTING RAISING cx_static_check.
    METHODS parse_up_to_rows FOR TESTING RAISING cx_static_check.
    METHODS parse_removes_into FOR TESTING RAISING cx_static_check.
    METHODS parse_union FOR TESTING RAISING cx_static_check.
    METHODS parse_order_by_descending FOR TESTING RAISING cx_static_check.
    METHODS parse_no_select_raises FOR TESTING RAISING cx_static_check.
    METHODS parse_no_from_raises FOR TESTING RAISING cx_static_check.
    METHODS sources_single_table FOR TESTING RAISING cx_static_check.
    METHODS sources_join_with_alias FOR TESTING RAISING cx_static_check.
    METHODS sources_join_without_alias FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_parser IMPLEMENTATION.

  METHOD normalize_multiline.

    DATA(lv_query) = `SELECT *` && cl_abap_char_utilities=>newline &&
                     `  FROM   t100  ` && cl_abap_char_utilities=>newline &&
                     `WHERE sprsl = 'E'`.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_sql_cl_query=>normalize( lv_query )
                                        exp = `SELECT * FROM t100 WHERE sprsl = 'E'` ).

  ENDMETHOD.

  METHOD parse_simple.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( query    = `select carrid connid from spfli`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID CONNID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 100 ).
    cl_abap_unit_assert=>assert_initial( lt_clauses[ 1 ]-where ).

  ENDMETHOD.

  METHOD parse_all_clauses.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse(
        `select carrid from spfli where carrid = 'AA' group by carrid having count( * ) > 1 order by carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrid = 'AA'` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-group_by
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-having
                                        exp = `count( * ) > 1` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD parse_single.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( query    = `SELECT SINGLE carrid FROM spfli`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 1 ).

  ENDMETHOD.

  METHOD parse_distinct.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( `SELECT DISTINCT carrid FROM spfli` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-distinct
                                        exp = abap_true ).

  ENDMETHOD.

  METHOD parse_up_to_rows.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( query    = `SELECT * FROM t100 UP TO 42 ROWS`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 42 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `T100` ).

  ENDMETHOD.

  METHOD parse_removes_into.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( `SELECT * FROM t100 INTO TABLE @lt_result WHERE sprsl = 'E'` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `T100` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `sprsl = 'E'` ).

  ENDMETHOD.

  METHOD parse_union.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( `SELECT carrid FROM spfli UNION SELECT carrid FROM scarr` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-from
                                        exp = `SCARR` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-select_list
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD parse_order_by_descending.

    DATA(lt_clauses) = z2ui5_sql_cl_query=>parse( `SELECT * FROM spfli ORDER BY carrid connid DESCENDING` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID, CONNID DESCENDING` ).

  ENDMETHOD.

  METHOD parse_no_select_raises.

    TRY.
        z2ui5_sql_cl_query=>parse( `DELETE FROM t100` ).
        cl_abap_unit_assert=>fail( ).
      CATCH z2ui5_cx_util_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD parse_no_from_raises.

    TRY.
        z2ui5_sql_cl_query=>parse( `SELECT carrid` ).
        cl_abap_unit_assert=>fail( ).
      CATCH z2ui5_cx_util_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD sources_single_table.

    DATA(lt_source) = z2ui5_sql_cl_query=>get_sources( `t100` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-name
                                        exp = `T100` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-alias
                                        exp = `T100` ).

  ENDMETHOD.

  METHOD sources_join_with_alias.

    DATA(lt_source) = z2ui5_sql_cl_query=>get_sources(
        `spfli AS a INNER JOIN scarr AS b ON a~carrid = b~carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-name
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-alias
                                        exp = `A` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 2 ]-name
                                        exp = `SCARR` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 2 ]-alias
                                        exp = `B` ).

  ENDMETHOD.

  METHOD sources_join_without_alias.

    DATA(lt_source) = z2ui5_sql_cl_query=>get_sources(
        `spfli LEFT OUTER JOIN scarr ON spfli~carrid = scarr~carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-name
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 2 ]-name
                                        exp = `SCARR` ).

  ENDMETHOD.

ENDCLASS.
