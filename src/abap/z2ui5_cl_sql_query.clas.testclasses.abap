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
    METHODS up_to_rows_capped FOR TESTING RAISING cx_static_check.
    METHODS up_to_zero_rows_capped FOR TESTING RAISING cx_static_check.
    METHODS up_to_rows_too_large FOR TESTING RAISING cx_static_check.
    METHODS parse_union_all FOR TESTING RAISING cx_static_check.
    METHODS parse_union_distinct FOR TESTING RAISING cx_static_check.
    METHODS union_deletes_duplicates FOR TESTING RAISING cx_static_check.
    METHODS union_order_by_columns FOR TESTING RAISING cx_static_check.
    METHODS union_order_by_unknown FOR TESTING RAISING cx_static_check.
    METHODS union_order_by_not_last FOR TESTING RAISING cx_static_check.
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

  METHOD up_to_rows_capped.

    " a larger UP TO overrode the cap of the console
    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 1000 ROWS`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 100 ).

  ENDMETHOD.

  METHOD up_to_zero_rows_capped.

    " UP TO 0 ROWS read every row of the table
    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 0 ROWS`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-rows
                                        exp = 100 ).

  ENDMETHOD.

  METHOD up_to_rows_too_large.

    TRY.
        z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 99999999999 ROWS`
                                   max_rows = 100 ).
        cl_abap_unit_assert=>fail( `a row count beyond type i must raise` ).
      CATCH z2ui5_cx_sql_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD parse_union_all.

    " UNION ALL SELECT was not split - the whole text was one segment
    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse( `SELECT carrid FROM spfli UNION ALL SELECT carrid FROM scarr` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 1 ]-from
                                        exp = `SPFLI` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-from
                                        exp = `SCARR` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-union_all
                                        exp = abap_true ).

  ENDMETHOD.

  METHOD parse_union_distinct.

    DATA(lt_clauses) = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM spfli UNION DISTINCT SELECT carrid FROM scarr union select carrid from sflight` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-from
                                        exp = `SCARR` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 2 ]-union_all
                                        exp = abap_false ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 3 ]-from
                                        exp = `SFLIGHT` ).
    cl_abap_unit_assert=>assert_equals( act = lt_clauses[ 3 ]-union_all
                                        exp = abap_false ).

  ENDMETHOD.

  METHOD union_deletes_duplicates.

    TYPES:
      BEGIN OF ty_s_row,
        f000001 TYPE string,
        f000002 TYPE i,
      END OF ty_s_row.
    DATA lt_data TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    lt_data = VALUE #( ( f000001 = `LH` f000002 = 2 )
                       ( f000001 = `AA` f000002 = 1 )
                       ( f000001 = `LH` f000002 = 1 )
                       ( f000001 = `LH` f000002 = 2 )
                       ( f000001 = `AA` f000002 = 1 ) ).

    z2ui5_cl_sql_query=>delete_duplicates(
      EXPORTING it_fieldlist = VALUE #( ( field = `F000001` ref_field = `CARRID` )
                                        ( field = `F000002` ref_field = `CONNID` ) )
      CHANGING  ct_data      = lt_data ).

    " typed, not VALUE #( ) in exp: the 7.02 downport cannot infer the type
    DATA lt_exp LIKE lt_data.
    lt_exp = VALUE #( ( f000001 = `AA` f000002 = 1 )
                      ( f000001 = `LH` f000002 = 1 )
                      ( f000001 = `LH` f000002 = 2 ) ).
    cl_abap_unit_assert=>assert_equals( act = lt_data
                                        exp = lt_exp ).

  ENDMETHOD.

  METHOD union_order_by_columns.

    TYPES:
      BEGIN OF ty_s_row,
        f000001 TYPE string,
        f000002 TYPE i,
      END OF ty_s_row.
    DATA lt_data TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.

    lt_data = VALUE #( ( f000001 = `AA` f000002 = 1 )
                       ( f000001 = `LH` f000002 = 1 )
                       ( f000001 = `AA` f000002 = 3 )
                       ( f000001 = `LH` f000002 = 2 ) ).

    " a column by alias and with table prefix, as the select list names them
    DATA(lt_order) = z2ui5_cl_sql_query=>get_order(
        order_by     = `A~CARRID DESCENDING, NUM`
        it_fieldlist = VALUE #( ( field = `F000001` ref_field = `CARRID` )
                                ( field = `F000002` ref_field = `NUM` ) ) ).
    z2ui5_cl_sql_query=>sort_rows( EXPORTING it_order = lt_order
                                   CHANGING  ct_data  = lt_data ).

    DATA lt_exp LIKE lt_data.
    lt_exp = VALUE #( ( f000001 = `LH` f000002 = 1 )
                      ( f000001 = `LH` f000002 = 2 )
                      ( f000001 = `AA` f000002 = 1 )
                      ( f000001 = `AA` f000002 = 3 ) ).
    cl_abap_unit_assert=>assert_equals( act = lt_data
                                        exp = lt_exp ).

  ENDMETHOD.

  METHOD union_order_by_unknown.

    TRY.
        z2ui5_cl_sql_query=>get_order( order_by     = `CONNID`
                                       it_fieldlist = VALUE #( ( field = `F000001` ref_field = `CARRID` ) ) ).
        cl_abap_unit_assert=>fail( `ORDER BY a column outside the result must raise` ).
      CATCH z2ui5_cx_sql_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

  METHOD union_order_by_not_last.

    " the ORDER BY of a segment in the middle sorted that segment only
    TRY.
        z2ui5_cl_sql_query=>run(
            `SELECT handle FROM z2ui5_t_33 ORDER BY handle UNION SELECT handle FROM z2ui5_t_33` ).
        cl_abap_unit_assert=>fail( `ORDER BY before the last SELECT of a UNION must raise` ).
      CATCH z2ui5_cx_sql_error ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

"! The history parse (z2ui5_cl_sql_context=>xml_srtti_parse): a stored
"! document is read back only when it names no class but the S-RTTI ones
CLASS ltcl_srtti DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS round_trip FOR TESTING RAISING cx_static_check.
    METHODS refuses_other_class FOR TESTING RAISING cx_static_check.
    METHODS refuses_default_class_ns FOR TESTING RAISING cx_static_check.
    METHODS refuses_char_reference FOR TESTING RAISING cx_static_check.
    METHODS refuses_doctype FOR TESTING RAISING cx_static_check.

    "! the document must be refused by the class check - a z2ui5_cx_sql_error
    METHODS assert_refused
      IMPORTING
        val TYPE string.

ENDCLASS.


CLASS ltcl_srtti IMPLEMENTATION.

  METHOD assert_refused.

    TRY.
        z2ui5_cl_sql_context=>xml_srtti_parse( val ).
        cl_abap_unit_assert=>fail( `the document must be refused` ).
      CATCH z2ui5_cx_sql_error INTO DATA(lx).
        " by the class check - not by a transformation that already ran
        cl_abap_unit_assert=>assert_char_cp( act = lx->get_text( )
                                             exp = `*not part of S-RTTI*` ).
    ENDTRY.

  ENDMETHOD.

  METHOD round_trip.

    DATA(lt_data) = VALUE string_table( ( `A` ) ( `B` ) ).

    DATA(lr_back) = z2ui5_cl_sql_context=>xml_srtti_parse(
        z2ui5_cl_sql_context=>xml_srtti_stringify( lt_data ) ).

    FIELD-SYMBOLS <back> TYPE string_table.
    ASSIGN lr_back->* TO <back>.
    cl_abap_unit_assert=>assert_equals( exp = lt_data
                                        act = <back> ).

  ENDMETHOD.

  METHOD refuses_other_class.

    " the same document, its S-RTTI objects named as objects of another class
    DATA lo_srtti TYPE REF TO z2ui5_cl_srt_typedescr.
    DATA(lo_ref) = CAST cl_abap_refdescr( cl_abap_typedescr=>describe_by_data( lo_srtti ) ).
    DATA(lv_class) = lo_ref->get_referenced_type( )->get_relative_name( ).
    DATA(lv_prefix) = substring( val = lv_class
                                 len = strlen( lv_class ) - strlen( `TYPEDESCR` ) ).

    DATA(lv_xml) = z2ui5_cl_sql_context=>xml_srtti_stringify( VALUE string_table( ( `A` ) ) ).
    cl_abap_unit_assert=>assert_char_cp( act = to_upper( lv_xml )
                                         exp = |*{ lv_prefix }*| ).
    REPLACE ALL OCCURRENCES OF lv_prefix IN lv_xml WITH `ZCL_OTHER_` IGNORING CASE.

    assert_refused( lv_xml ).

  ENDMETHOD.

  METHOD refuses_default_class_ns.

    assert_refused( `<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">`
                 && `<asx:values><SRTTI href="#o1"/></asx:values>`
                 && `<asx:heap xmlns="http://www.sap.com/abapxml/classes/global"><CL_OTHER id="o1"/></asx:heap>`
                 && `</asx:abap>` ).

  ENDMETHOD.

  METHOD refuses_char_reference.

    assert_refused( `<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0">`
                 && `<asx:values><SRTTI href="#o1"/></asx:values>`
                 && `<asx:heap xmlns:c="http&#58;//www.sap.com/abapxml/classes/global"><c:CL_OTHER id="o1"/></asx:heap>`
                 && `</asx:abap>` ).

  ENDMETHOD.

  METHOD refuses_doctype.

    assert_refused( `<!DOCTYPE asx:abap [ <!ENTITY c "classes"> ]>`
                 && `<asx:abap xmlns:asx="http://www.sap.com/abapxml" version="1.0"><asx:values/></asx:abap>` ).

  ENDMETHOD.

ENDCLASS.
