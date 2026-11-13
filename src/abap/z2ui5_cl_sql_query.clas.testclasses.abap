CLASS ltcl_parser DEFINITION DEFERRED.
CLASS z2ui5_cl_sql_query DEFINITION LOCAL FRIENDS ltcl_parser.

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
    METHODS run_alias_without_prefix FOR TESTING RAISING cx_static_check.
    METHODS parse_case_literals FOR TESTING RAISING cx_static_check.
    METHODS parse_where_literal FOR TESTING RAISING cx_static_check.
    METHODS parse_escaped_quote FOR TESTING RAISING cx_static_check.
    METHODS parse_mixed_case_identifiers FOR TESTING RAISING cx_static_check.
    METHODS target_case_literal_comma FOR TESTING RAISING cx_static_check.
    METHODS keyword_in_where_literal FOR TESTING RAISING cx_static_check.
    METHODS keyword_in_select_literal FOR TESTING RAISING cx_static_check.
    METHODS keyword_in_having_literal FOR TESTING RAISING cx_static_check.
    METHODS union_in_literal FOR TESTING RAISING cx_static_check.
    METHODS up_to_into_in_literal FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_parser IMPLEMENTATION.

  METHOD normalize_multiline.

    DATA(lv_query) = `SELECT *` && cl_abap_char_utilities=>newline &&
                     `  FROM   t100  ` && cl_abap_char_utilities=>newline &&
                     `WHERE sprsl = 'E'`.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_sql_query=>normalize( lv_query )
                                        exp = `SELECT * FROM t100 WHERE sprsl = 'E'` ).

  ENDMETHOD.

  METHOD parse_simple.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( query    = `select carrid connid from spfli`
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

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
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

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( query    = `SELECT SINGLE carrid FROM spfli`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 1 ).

  ENDMETHOD.

  METHOD parse_distinct.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( `SELECT DISTINCT carrid FROM spfli` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-distinct
                                        exp = abap_true ).

  ENDMETHOD.

  METHOD parse_up_to_rows.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 42 ROWS`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 42 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `T100` ).

  ENDMETHOD.

  METHOD parse_removes_into.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( `SELECT * FROM t100 INTO TABLE @lt_result WHERE sprsl = 'E'` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `T100` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `sprsl = 'E'` ).

  ENDMETHOD.

  METHOD parse_union.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( `SELECT carrid FROM spfli UNION SELECT carrid FROM scarr` ).

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

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( `SELECT * FROM spfli ORDER BY carrid connid DESCENDING` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID, CONNID DESCENDING` ).

  ENDMETHOD.

  METHOD parse_no_select_raises.

    TRY.
        z2ui5_cl_sql_query=>parse( `DELETE FROM t100` ).
        cl_abap_unit_assert=>fail( ).
      CATCH z2ui5_cx_sql_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD parse_no_from_raises.

    TRY.
        z2ui5_cl_sql_query=>parse( `SELECT carrid` ).
        cl_abap_unit_assert=>fail( ).
      CATCH z2ui5_cx_sql_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD sources_single_table.

    DATA(lt_source) = z2ui5_cl_sql_query=>get_sources( `t100` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-name
                                        exp = `T100` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-alias
                                        exp = `T100` ).

  ENDMETHOD.

  METHOD sources_join_with_alias.

    DATA(lt_source) = z2ui5_cl_sql_query=>get_sources(
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

    DATA(lt_source) = z2ui5_cl_sql_query=>get_sources(
        `spfli LEFT OUTER JOIN scarr ON spfli~carrid = scarr~carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 1 ]-name
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_source[ 2 ]-name
                                        exp = `SCARR` ).

  ENDMETHOD.

  METHOD run_alias_without_prefix.

    " a field without a table prefix, renamed with AS - the column was
    " looked up as `HANDLE AS H` and the query refused
    DATA(ls_result) = z2ui5_cl_sql_query=>run( `SELECT handle AS h FROM z2ui5_t_33` ).

    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-fieldlist )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-fieldlist[ 1 ]-ref_field
                                        exp = `H` ).
    cl_abap_unit_assert=>assert_equals( act = ls_result-fieldlist[ 1 ]-ref_table
                                        exp = `Z2UI5_T_33` ).

  ENDMETHOD.

  METHOD parse_case_literals.

    " literals keep their case - upper-casing the whole select list
    " turned 'lh' into 'LH' and changed both comparison and output
    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN carrid = 'lh' THEN 'Lufthansa' ELSE 'other' END AS name FROM scarr` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CASE WHEN CARRID = 'lh' THEN 'Lufthansa' ELSE 'other' END AS NAME` ).

  ENDMETHOD.

  METHOD parse_where_literal.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( `SELECT * FROM scarr WHERE carrname = 'Lufthansa'` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrname = 'Lufthansa'` ).

    " blanks inside a literal are content, not layout
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT * FROM scarr WHERE carrname = 'Air  Berlin '` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrname = 'Air  Berlin '` ).

  ENDMETHOD.

  METHOD parse_escaped_quote.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN uname = 'o''neil' THEN 'it''s me' ELSE 'no' END AS n FROM z2ui5_t_33 WHERE uname <> 'O''Neil'` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CASE WHEN UNAME = 'o''neil' THEN 'it''s me' ELSE 'no' END AS N` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `uname <> 'O''Neil'` ).

  ENDMETHOD.

  METHOD parse_mixed_case_identifiers.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SeLeCt CarrId, CaSe WhEn CarrId = 'lh' ThEn 'x' EnD As Nm FrOm sCaRr As s GrOuP By CarrId OrDeR By CarrId` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CARRID, CASE WHEN CARRID = 'lh' THEN 'x' END AS NM` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SCARR AS S` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-group_by
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD target_case_literal_comma.

    " a comma or a double blank inside a literal is not a separator
    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN uname = 'a, b' THEN 'x  y' ELSE 'end' END AS n FROM z2ui5_t_33` ).
    DATA(ls_target) = z2ui5_cl_sql_query=>build_target( lt_clauses[ 1 ] ).

    cl_abap_unit_assert=>assert_equals( act = ls_target-select_list
                                        exp = `CASE WHEN UNAME = 'a, b' THEN 'x  y' ELSE 'end' END AS N` ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_target-fieldlist )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = ls_target-fieldlist[ 1 ]-ref_field
                                        exp = `N` ).

  ENDMETHOD.

  METHOD keyword_in_where_literal.

    " a clause keyword inside a literal does not end the clause
    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT * FROM scarr WHERE carrname = ' from ' OR carrname = 'x ORDER BY y' ORDER BY carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SCARR` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrname = ' from ' OR carrname = 'x ORDER BY y'` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD keyword_in_select_literal.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN carrid = 'lh' THEN 'from x' ELSE ' FROM y WHERE ' END AS n FROM scarr WHERE carrid = 'LH'` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-select_list
                                        exp = `CASE WHEN CARRID = 'lh' THEN 'from x' ELSE ' FROM y WHERE ' END AS N` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SCARR` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrid = 'LH'` ).

  ENDMETHOD.

  METHOD keyword_in_having_literal.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM spfli GROUP BY carrid HAVING max( cityfrom ) <> ' where ' ORDER BY carrid` ).

    cl_abap_unit_assert=>assert_initial( lt_clauses[ 1 ]-where ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-group_by
                                        exp = `CARRID` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-having
                                        exp = `max( cityfrom ) <> ' where '` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID` ).

    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM spfli GROUP BY carrid HAVING max( cityto ) <> ' order by x ' ORDER BY carrid DESCENDING` ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-having
                                        exp = `max( cityto ) <> ' order by x '` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-order_by
                                        exp = `CARRID DESCENDING` ).

  ENDMETHOD.

  METHOD union_in_literal.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM scarr WHERE carrname = 'a UNION SELECT b' UNION SELECT carrid FROM spfli` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrname = 'a UNION SELECT b'` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-from
                                        exp = `SPFLI` ).

  ENDMETHOD.

  METHOD up_to_into_in_literal.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM scarr WHERE carrname = 'up to 5 rows into x'`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 100 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-where
                                        exp = `carrname = 'up to 5 rows into x'` ).

  ENDMETHOD.

ENDCLASS.
