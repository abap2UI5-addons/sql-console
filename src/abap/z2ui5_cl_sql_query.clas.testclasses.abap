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

    DATA lv_query TYPE string.
    lv_query = `SELECT *` && cl_abap_char_utilities=>newline &&
                     `  FROM   t100  ` && cl_abap_char_utilities=>newline &&
                     `WHERE sprsl = 'E'`.

    cl_abap_unit_assert=>assert_equals( act = z2ui5_cl_sql_query=>normalize( lv_query )
                                        exp = `SELECT * FROM t100 WHERE sprsl = 'E'` ).

  ENDMETHOD.

  METHOD parse_simple.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_clauses.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_clauses.
    DATA temp4 LIKE sy-tabix.
    FIELD-SYMBOLS <temp5> LIKE LINE OF lt_clauses.
    DATA temp6 LIKE sy-tabix.
    FIELD-SYMBOLS <temp7> LIKE LINE OF lt_clauses.
    DATA temp8 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( query    = `select carrid connid from spfli`
                                                  max_rows = 100 ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 1 ).


    temp2 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp1>-select_list
                                        exp = `CARRID CONNID` ).


    temp4 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp3>-from
                                        exp = `SPFLI` ).


    temp6 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp5>.
    sy-tabix = temp6.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp5>-rows
                                        exp = 100 ).


    temp8 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp7>.
    sy-tabix = temp8.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp7>-where ).

  ENDMETHOD.

  METHOD parse_all_clauses.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp9> LIKE LINE OF lt_clauses.
    DATA temp10 LIKE sy-tabix.
    FIELD-SYMBOLS <temp11> LIKE LINE OF lt_clauses.
    DATA temp12 LIKE sy-tabix.
    FIELD-SYMBOLS <temp13> LIKE LINE OF lt_clauses.
    DATA temp14 LIKE sy-tabix.
    FIELD-SYMBOLS <temp15> LIKE LINE OF lt_clauses.
    DATA temp16 LIKE sy-tabix.
    FIELD-SYMBOLS <temp17> LIKE LINE OF lt_clauses.
    DATA temp18 LIKE sy-tabix.
    FIELD-SYMBOLS <temp19> LIKE LINE OF lt_clauses.
    DATA temp20 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `select carrid from spfli where carrid = 'AA' group by carrid having count( * ) > 1 order by carrid` ).



    temp10 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp9>.
    sy-tabix = temp10.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp9>-select_list
                                        exp = `CARRID` ).


    temp12 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp11>.
    sy-tabix = temp12.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp11>-from
                                        exp = `SPFLI` ).


    temp14 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp13>.
    sy-tabix = temp14.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp13>-where
                                        exp = `carrid = 'AA'` ).


    temp16 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp15>.
    sy-tabix = temp16.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp15>-group_by
                                        exp = `CARRID` ).


    temp18 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp17>-having
                                        exp = `count( * ) > 1` ).


    temp20 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp19>-order_by
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD parse_single.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp21> LIKE LINE OF lt_clauses.
    DATA temp22 LIKE sy-tabix.
    FIELD-SYMBOLS <temp23> LIKE LINE OF lt_clauses.
    DATA temp24 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( query    = `SELECT SINGLE carrid FROM spfli`
                                                  max_rows = 100 ).



    temp22 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp21>-select_list
                                        exp = `CARRID` ).


    temp24 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp23>.
    sy-tabix = temp24.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp23>-rows
                                        exp = 1 ).

  ENDMETHOD.

  METHOD parse_distinct.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp25> LIKE LINE OF lt_clauses.
    DATA temp26 LIKE sy-tabix.
    FIELD-SYMBOLS <temp27> LIKE LINE OF lt_clauses.
    DATA temp28 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT DISTINCT carrid FROM spfli` ).



    temp26 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp25>.
    sy-tabix = temp26.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp25>-select_list
                                        exp = `CARRID` ).


    temp28 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp27>.
    sy-tabix = temp28.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp27>-distinct
                                        exp = abap_true ).

  ENDMETHOD.

  METHOD parse_up_to_rows.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp29> LIKE LINE OF lt_clauses.
    DATA temp30 LIKE sy-tabix.
    FIELD-SYMBOLS <temp31> LIKE LINE OF lt_clauses.
    DATA temp32 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 42 ROWS`
                                                  max_rows = 100 ).



    temp30 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp29>.
    sy-tabix = temp30.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp29>-rows
                                        exp = 42 ).


    temp32 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp31>.
    sy-tabix = temp32.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp31>-from
                                        exp = `T100` ).

  ENDMETHOD.

  METHOD parse_removes_into.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp33> LIKE LINE OF lt_clauses.
    DATA temp34 LIKE sy-tabix.
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_clauses.
    DATA temp36 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT * FROM t100 INTO TABLE @lt_result WHERE sprsl = 'E'` ).



    temp34 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp33>.
    sy-tabix = temp34.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp33>-from
                                        exp = `T100` ).


    temp36 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp35>-where
                                        exp = `sprsl = 'E'` ).

  ENDMETHOD.

  METHOD parse_union.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_clauses.
    DATA temp38 LIKE sy-tabix.
    FIELD-SYMBOLS <temp39> LIKE LINE OF lt_clauses.
    DATA temp40 LIKE sy-tabix.
    FIELD-SYMBOLS <temp41> LIKE LINE OF lt_clauses.
    DATA temp42 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT carrid FROM spfli UNION SELECT carrid FROM scarr` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 2 ).


    temp38 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp37>-from
                                        exp = `SPFLI` ).


    temp40 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp39>.
    sy-tabix = temp40.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp39>-from
                                        exp = `SCARR` ).


    temp42 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp41>-select_list
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD parse_order_by_descending.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp43> LIKE LINE OF lt_clauses.
    DATA temp44 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT * FROM spfli ORDER BY carrid connid DESCENDING` ).



    temp44 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp43>.
    sy-tabix = temp44.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp43>-order_by
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

    DATA lt_source TYPE z2ui5_cl_sql_query=>ty_t_source.
    FIELD-SYMBOLS <temp45> LIKE LINE OF lt_source.
    DATA temp46 LIKE sy-tabix.
    FIELD-SYMBOLS <temp47> LIKE LINE OF lt_source.
    DATA temp48 LIKE sy-tabix.
    lt_source = z2ui5_cl_sql_query=>get_sources( `t100` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 1 ).


    temp46 = sy-tabix.
    READ TABLE lt_source INDEX 1 ASSIGNING <temp45>.
    sy-tabix = temp46.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp45>-name
                                        exp = `T100` ).


    temp48 = sy-tabix.
    READ TABLE lt_source INDEX 1 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp47>-alias
                                        exp = `T100` ).

  ENDMETHOD.

  METHOD sources_join_with_alias.

    DATA lt_source TYPE z2ui5_cl_sql_query=>ty_t_source.
    FIELD-SYMBOLS <temp49> LIKE LINE OF lt_source.
    DATA temp50 LIKE sy-tabix.
    FIELD-SYMBOLS <temp51> LIKE LINE OF lt_source.
    DATA temp52 LIKE sy-tabix.
    FIELD-SYMBOLS <temp53> LIKE LINE OF lt_source.
    DATA temp54 LIKE sy-tabix.
    FIELD-SYMBOLS <temp55> LIKE LINE OF lt_source.
    DATA temp56 LIKE sy-tabix.
    lt_source = z2ui5_cl_sql_query=>get_sources(
        `spfli AS a INNER JOIN scarr AS b ON a~carrid = b~carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 2 ).


    temp50 = sy-tabix.
    READ TABLE lt_source INDEX 1 ASSIGNING <temp49>.
    sy-tabix = temp50.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp49>-name
                                        exp = `SPFLI` ).


    temp52 = sy-tabix.
    READ TABLE lt_source INDEX 1 ASSIGNING <temp51>.
    sy-tabix = temp52.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp51>-alias
                                        exp = `A` ).


    temp54 = sy-tabix.
    READ TABLE lt_source INDEX 2 ASSIGNING <temp53>.
    sy-tabix = temp54.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp53>-name
                                        exp = `SCARR` ).


    temp56 = sy-tabix.
    READ TABLE lt_source INDEX 2 ASSIGNING <temp55>.
    sy-tabix = temp56.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp55>-alias
                                        exp = `B` ).

  ENDMETHOD.

  METHOD sources_join_without_alias.

    DATA lt_source TYPE z2ui5_cl_sql_query=>ty_t_source.
    FIELD-SYMBOLS <temp57> LIKE LINE OF lt_source.
    DATA temp58 LIKE sy-tabix.
    FIELD-SYMBOLS <temp59> LIKE LINE OF lt_source.
    DATA temp60 LIKE sy-tabix.
    lt_source = z2ui5_cl_sql_query=>get_sources(
        `spfli LEFT OUTER JOIN scarr ON spfli~carrid = scarr~carrid` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_source )
                                        exp = 2 ).


    temp58 = sy-tabix.
    READ TABLE lt_source INDEX 1 ASSIGNING <temp57>.
    sy-tabix = temp58.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp57>-name
                                        exp = `SPFLI` ).


    temp60 = sy-tabix.
    READ TABLE lt_source INDEX 2 ASSIGNING <temp59>.
    sy-tabix = temp60.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp59>-name
                                        exp = `SCARR` ).

  ENDMETHOD.

  METHOD run_alias_without_prefix.

    " a field without a table prefix, renamed with AS - the column was
    " looked up as `HANDLE AS H` and the query refused
    DATA ls_result TYPE z2ui5_cl_sql_query=>ty_s_result.
    FIELD-SYMBOLS <temp61> LIKE LINE OF ls_result-fieldlist.
    DATA temp62 LIKE sy-tabix.
    FIELD-SYMBOLS <temp63> LIKE LINE OF ls_result-fieldlist.
    DATA temp64 LIKE sy-tabix.
    ls_result = z2ui5_cl_sql_query=>run( `SELECT handle AS h FROM z2ui5_t_33` ).

    cl_abap_unit_assert=>assert_equals( act = lines( ls_result-fieldlist )
                                        exp = 1 ).


    temp62 = sy-tabix.
    READ TABLE ls_result-fieldlist INDEX 1 ASSIGNING <temp61>.
    sy-tabix = temp62.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp61>-ref_field
                                        exp = `H` ).


    temp64 = sy-tabix.
    READ TABLE ls_result-fieldlist INDEX 1 ASSIGNING <temp63>.
    sy-tabix = temp64.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp63>-ref_table
                                        exp = `Z2UI5_T_33` ).

  ENDMETHOD.

  METHOD parse_case_literals.

    " literals keep their case - upper-casing the whole select list
    " turned 'lh' into 'LH' and changed both comparison and output
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp65> LIKE LINE OF lt_clauses.
    DATA temp66 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN carrid = 'lh' THEN 'Lufthansa' ELSE 'other' END AS name FROM scarr` ).



    temp66 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp65>.
    sy-tabix = temp66.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp65>-select_list
                                        exp = `CASE WHEN CARRID = 'lh' THEN 'Lufthansa' ELSE 'other' END AS NAME` ).

  ENDMETHOD.

  METHOD parse_where_literal.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp67> LIKE LINE OF lt_clauses.
    DATA temp68 LIKE sy-tabix.
    FIELD-SYMBOLS <temp69> LIKE LINE OF lt_clauses.
    DATA temp70 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT * FROM scarr WHERE carrname = 'Lufthansa'` ).



    temp68 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp67>.
    sy-tabix = temp68.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp67>-where
                                        exp = `carrname = 'Lufthansa'` ).

    " blanks inside a literal are content, not layout
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT * FROM scarr WHERE carrname = 'Air  Berlin '` ).



    temp70 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp69>.
    sy-tabix = temp70.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp69>-where
                                        exp = `carrname = 'Air  Berlin '` ).

  ENDMETHOD.

  METHOD parse_escaped_quote.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp71> LIKE LINE OF lt_clauses.
    DATA temp72 LIKE sy-tabix.
    FIELD-SYMBOLS <temp73> LIKE LINE OF lt_clauses.
    DATA temp74 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN uname = 'o''neil' THEN 'it''s me' ELSE 'no' END AS n FROM z2ui5_t_33 WHERE uname <> 'O''Neil'` ).



    temp72 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp71>.
    sy-tabix = temp72.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp71>-select_list
                                        exp = `CASE WHEN UNAME = 'o''neil' THEN 'it''s me' ELSE 'no' END AS N` ).


    temp74 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp73>.
    sy-tabix = temp74.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp73>-where
                                        exp = `uname <> 'O''Neil'` ).

  ENDMETHOD.

  METHOD parse_mixed_case_identifiers.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp75> LIKE LINE OF lt_clauses.
    DATA temp76 LIKE sy-tabix.
    FIELD-SYMBOLS <temp77> LIKE LINE OF lt_clauses.
    DATA temp78 LIKE sy-tabix.
    FIELD-SYMBOLS <temp79> LIKE LINE OF lt_clauses.
    DATA temp80 LIKE sy-tabix.
    FIELD-SYMBOLS <temp81> LIKE LINE OF lt_clauses.
    DATA temp82 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SeLeCt CarrId, CaSe WhEn CarrId = 'lh' ThEn 'x' EnD As Nm FrOm sCaRr As s GrOuP By CarrId OrDeR By CarrId` ).



    temp76 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp75>.
    sy-tabix = temp76.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp75>-select_list
                                        exp = `CARRID, CASE WHEN CARRID = 'lh' THEN 'x' END AS NM` ).


    temp78 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp77>.
    sy-tabix = temp78.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp77>-from
                                        exp = `SCARR AS S` ).


    temp80 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp79>.
    sy-tabix = temp80.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp79>-group_by
                                        exp = `CARRID` ).


    temp82 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp81>.
    sy-tabix = temp82.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp81>-order_by
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD target_case_literal_comma.

    " a comma or a double blank inside a literal is not a separator
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    DATA ls_target TYPE z2ui5_cl_sql_query=>ty_s_target.
    FIELD-SYMBOLS <temp1> LIKE LINE OF lt_clauses.
    DATA temp2 LIKE sy-tabix.
    FIELD-SYMBOLS <temp83> LIKE LINE OF ls_target-fieldlist.
    DATA temp84 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN uname = 'a, b' THEN 'x  y' ELSE 'end' END AS n FROM z2ui5_t_33` ).



    temp2 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp1>.
    sy-tabix = temp2.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_target = z2ui5_cl_sql_query=>build_target( <temp1> ).

    cl_abap_unit_assert=>assert_equals( act = ls_target-select_list
                                        exp = `CASE WHEN UNAME = 'a, b' THEN 'x  y' ELSE 'end' END AS N` ).
    cl_abap_unit_assert=>assert_equals( act = lines( ls_target-fieldlist )
                                        exp = 1 ).


    temp84 = sy-tabix.
    READ TABLE ls_target-fieldlist INDEX 1 ASSIGNING <temp83>.
    sy-tabix = temp84.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp83>-ref_field
                                        exp = `N` ).

  ENDMETHOD.

  METHOD keyword_in_where_literal.

    " a clause keyword inside a literal does not end the clause
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp85> LIKE LINE OF lt_clauses.
    DATA temp86 LIKE sy-tabix.
    FIELD-SYMBOLS <temp87> LIKE LINE OF lt_clauses.
    DATA temp88 LIKE sy-tabix.
    FIELD-SYMBOLS <temp89> LIKE LINE OF lt_clauses.
    DATA temp90 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT * FROM scarr WHERE carrname = ' from ' OR carrname = 'x ORDER BY y' ORDER BY carrid` ).



    temp86 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp85>.
    sy-tabix = temp86.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp85>-from
                                        exp = `SCARR` ).


    temp88 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp87>.
    sy-tabix = temp88.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp87>-where
                                        exp = `carrname = ' from ' OR carrname = 'x ORDER BY y'` ).


    temp90 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp89>.
    sy-tabix = temp90.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp89>-order_by
                                        exp = `CARRID` ).

  ENDMETHOD.

  METHOD keyword_in_select_literal.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp91> LIKE LINE OF lt_clauses.
    DATA temp92 LIKE sy-tabix.
    FIELD-SYMBOLS <temp93> LIKE LINE OF lt_clauses.
    DATA temp94 LIKE sy-tabix.
    FIELD-SYMBOLS <temp95> LIKE LINE OF lt_clauses.
    DATA temp96 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT CASE WHEN carrid = 'lh' THEN 'from x' ELSE ' FROM y WHERE ' END AS n FROM scarr WHERE carrid = 'LH'` ).



    temp92 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp91>.
    sy-tabix = temp92.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp91>-select_list
                                        exp = `CASE WHEN CARRID = 'lh' THEN 'from x' ELSE ' FROM y WHERE ' END AS N` ).


    temp94 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp93>.
    sy-tabix = temp94.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp93>-from
                                        exp = `SCARR` ).


    temp96 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp95>.
    sy-tabix = temp96.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp95>-where
                                        exp = `carrid = 'LH'` ).

  ENDMETHOD.

  METHOD keyword_in_having_literal.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp97> LIKE LINE OF lt_clauses.
    DATA temp98 LIKE sy-tabix.
    FIELD-SYMBOLS <temp99> LIKE LINE OF lt_clauses.
    DATA temp100 LIKE sy-tabix.
    FIELD-SYMBOLS <temp101> LIKE LINE OF lt_clauses.
    DATA temp102 LIKE sy-tabix.
    FIELD-SYMBOLS <temp103> LIKE LINE OF lt_clauses.
    DATA temp104 LIKE sy-tabix.
    FIELD-SYMBOLS <temp105> LIKE LINE OF lt_clauses.
    DATA temp106 LIKE sy-tabix.
    FIELD-SYMBOLS <temp107> LIKE LINE OF lt_clauses.
    DATA temp108 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM spfli GROUP BY carrid HAVING max( cityfrom ) <> ' where ' ORDER BY carrid` ).



    temp98 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp97>.
    sy-tabix = temp98.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp97>-where ).


    temp100 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp99>.
    sy-tabix = temp100.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp99>-group_by
                                        exp = `CARRID` ).


    temp102 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp101>.
    sy-tabix = temp102.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp101>-having
                                        exp = `max( cityfrom ) <> ' where '` ).


    temp104 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp103>.
    sy-tabix = temp104.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp103>-order_by
                                        exp = `CARRID` ).

    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM spfli GROUP BY carrid HAVING max( cityto ) <> ' order by x ' ORDER BY carrid DESCENDING` ).



    temp106 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp105>.
    sy-tabix = temp106.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp105>-having
                                        exp = `max( cityto ) <> ' order by x '` ).


    temp108 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp107>.
    sy-tabix = temp108.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp107>-order_by
                                        exp = `CARRID DESCENDING` ).

  ENDMETHOD.

  METHOD union_in_literal.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp109> LIKE LINE OF lt_clauses.
    DATA temp110 LIKE sy-tabix.
    FIELD-SYMBOLS <temp111> LIKE LINE OF lt_clauses.
    DATA temp112 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM scarr WHERE carrname = 'a UNION SELECT b' UNION SELECT carrid FROM spfli` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 2 ).


    temp110 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp109>.
    sy-tabix = temp110.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp109>-where
                                        exp = `carrname = 'a UNION SELECT b'` ).


    temp112 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp111>.
    sy-tabix = temp112.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp111>-from
                                        exp = `SPFLI` ).

  ENDMETHOD.

  METHOD up_to_into_in_literal.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp113> LIKE LINE OF lt_clauses.
    DATA temp114 LIKE sy-tabix.
    FIELD-SYMBOLS <temp115> LIKE LINE OF lt_clauses.
    DATA temp116 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM scarr WHERE carrname = 'up to 5 rows into x'`
                                                  max_rows = 100 ).



    temp114 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp113>.
    sy-tabix = temp114.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp113>-rows
                                        exp = 100 ).


    temp116 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp115>.
    sy-tabix = temp116.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp115>-where
                                        exp = `carrname = 'up to 5 rows into x'` ).

  ENDMETHOD.

  METHOD up_to_rows_capped.

    " a larger UP TO overrode the cap of the console
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp117> LIKE LINE OF lt_clauses.
    DATA temp118 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 1000 ROWS`
                                                  max_rows = 100 ).



    temp118 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp117>.
    sy-tabix = temp118.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp117>-rows
                                        exp = 100 ).

  ENDMETHOD.

  METHOD up_to_zero_rows_capped.

    " UP TO 0 ROWS read every row of the table
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp119> LIKE LINE OF lt_clauses.
    DATA temp120 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( query    = `SELECT * FROM t100 UP TO 0 ROWS`
                                                  max_rows = 100 ).



    temp120 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp119>.
    sy-tabix = temp120.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp119>-rows
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
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp121> LIKE LINE OF lt_clauses.
    DATA temp122 LIKE sy-tabix.
    FIELD-SYMBOLS <temp123> LIKE LINE OF lt_clauses.
    DATA temp124 LIKE sy-tabix.
    FIELD-SYMBOLS <temp125> LIKE LINE OF lt_clauses.
    DATA temp126 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse( `SELECT carrid FROM spfli UNION ALL SELECT carrid FROM scarr` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 2 ).


    temp122 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp121>.
    sy-tabix = temp122.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp121>-from
                                        exp = `SPFLI` ).


    temp124 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp123>.
    sy-tabix = temp124.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp123>-from
                                        exp = `SCARR` ).


    temp126 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp125>.
    sy-tabix = temp126.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp125>-union_all
                                        exp = abap_true ).

  ENDMETHOD.

  METHOD parse_union_distinct.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    FIELD-SYMBOLS <temp127> LIKE LINE OF lt_clauses.
    DATA temp128 LIKE sy-tabix.
    FIELD-SYMBOLS <temp129> LIKE LINE OF lt_clauses.
    DATA temp130 LIKE sy-tabix.
    FIELD-SYMBOLS <temp131> LIKE LINE OF lt_clauses.
    DATA temp132 LIKE sy-tabix.
    FIELD-SYMBOLS <temp133> LIKE LINE OF lt_clauses.
    DATA temp134 LIKE sy-tabix.
    lt_clauses = z2ui5_cl_sql_query=>parse(
        `SELECT carrid FROM spfli UNION DISTINCT SELECT carrid FROM scarr union select carrid from sflight` ).

    cl_abap_unit_assert=>assert_equals( act = lines( lt_clauses )
                                        exp = 3 ).


    temp128 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp127>.
    sy-tabix = temp128.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp127>-from
                                        exp = `SCARR` ).


    temp130 = sy-tabix.
    READ TABLE lt_clauses INDEX 2 ASSIGNING <temp129>.
    sy-tabix = temp130.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp129>-union_all
                                        exp = abap_false ).


    temp132 = sy-tabix.
    READ TABLE lt_clauses INDEX 3 ASSIGNING <temp131>.
    sy-tabix = temp132.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp131>-from
                                        exp = `SFLIGHT` ).


    temp134 = sy-tabix.
    READ TABLE lt_clauses INDEX 3 ASSIGNING <temp133>.
    sy-tabix = temp134.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( act = <temp133>-union_all
                                        exp = abap_false ).

  ENDMETHOD.

  METHOD union_deletes_duplicates.

    TYPES:
      BEGIN OF ty_s_row,
        f000001 TYPE string,
        f000002 TYPE i,
      END OF ty_s_row.
    TYPES temp1 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA lt_data TYPE temp1.

    DATA temp135 LIKE lt_data.
    DATA temp136 LIKE LINE OF temp135.
    DATA temp137 TYPE z2ui5_cl_sql_query=>ty_t_fieldlist.
    DATA temp138 LIKE LINE OF temp137.
    DATA lt_exp LIKE lt_data.
    DATA temp139 LIKE lt_exp.
    DATA temp140 LIKE LINE OF temp139.
    CLEAR temp135.

    temp136-f000001 = `LH`.
    temp136-f000002 = 2.
    INSERT temp136 INTO TABLE temp135.
    temp136-f000001 = `AA`.
    temp136-f000002 = 1.
    INSERT temp136 INTO TABLE temp135.
    temp136-f000001 = `LH`.
    temp136-f000002 = 1.
    INSERT temp136 INTO TABLE temp135.
    temp136-f000001 = `LH`.
    temp136-f000002 = 2.
    INSERT temp136 INTO TABLE temp135.
    temp136-f000001 = `AA`.
    temp136-f000002 = 1.
    INSERT temp136 INTO TABLE temp135.
    lt_data = temp135.


    CLEAR temp137.

    temp138-field = `F000001`.
    temp138-ref_field = `CARRID`.
    INSERT temp138 INTO TABLE temp137.
    temp138-field = `F000002`.
    temp138-ref_field = `CONNID`.
    INSERT temp138 INTO TABLE temp137.
    z2ui5_cl_sql_query=>delete_duplicates(
      EXPORTING it_fieldlist = temp137
      CHANGING  ct_data      = lt_data ).

    " typed, not VALUE #( ) in exp: the 7.02 downport cannot infer the type


    CLEAR temp139.

    temp140-f000001 = `AA`.
    temp140-f000002 = 1.
    INSERT temp140 INTO TABLE temp139.
    temp140-f000001 = `LH`.
    temp140-f000002 = 1.
    INSERT temp140 INTO TABLE temp139.
    temp140-f000001 = `LH`.
    temp140-f000002 = 2.
    INSERT temp140 INTO TABLE temp139.
    lt_exp = temp139.
    cl_abap_unit_assert=>assert_equals( act = lt_data
                                        exp = lt_exp ).

  ENDMETHOD.

  METHOD union_order_by_columns.

    TYPES:
      BEGIN OF ty_s_row,
        f000001 TYPE string,
        f000002 TYPE i,
      END OF ty_s_row.
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_row WITH DEFAULT KEY.
DATA lt_data TYPE temp2.

    DATA temp141 LIKE lt_data.
    DATA temp142 LIKE LINE OF temp141.
    DATA temp143 TYPE z2ui5_cl_sql_query=>ty_t_fieldlist.
    DATA temp144 LIKE LINE OF temp143.
    DATA lt_order TYPE z2ui5_cl_sql_query=>ty_t_order.
    DATA lt_exp LIKE lt_data.
    DATA temp145 LIKE lt_exp.
    DATA temp146 LIKE LINE OF temp145.
    CLEAR temp141.

    temp142-f000001 = `AA`.
    temp142-f000002 = 1.
    INSERT temp142 INTO TABLE temp141.
    temp142-f000001 = `LH`.
    temp142-f000002 = 1.
    INSERT temp142 INTO TABLE temp141.
    temp142-f000001 = `AA`.
    temp142-f000002 = 3.
    INSERT temp142 INTO TABLE temp141.
    temp142-f000001 = `LH`.
    temp142-f000002 = 2.
    INSERT temp142 INTO TABLE temp141.
    lt_data = temp141.

    " a column by alias and with table prefix, as the select list names them

    CLEAR temp143.

    temp144-field = `F000001`.
    temp144-ref_field = `CARRID`.
    INSERT temp144 INTO TABLE temp143.
    temp144-field = `F000002`.
    temp144-ref_field = `NUM`.
    INSERT temp144 INTO TABLE temp143.

    lt_order = z2ui5_cl_sql_query=>get_order(
        order_by     = `A~CARRID DESCENDING, NUM`
        it_fieldlist = temp143 ).
    z2ui5_cl_sql_query=>sort_rows( EXPORTING it_order = lt_order
                                   CHANGING  ct_data  = lt_data ).



    CLEAR temp145.

    temp146-f000001 = `LH`.
    temp146-f000002 = 1.
    INSERT temp146 INTO TABLE temp145.
    temp146-f000001 = `LH`.
    temp146-f000002 = 2.
    INSERT temp146 INTO TABLE temp145.
    temp146-f000001 = `AA`.
    temp146-f000002 = 1.
    INSERT temp146 INTO TABLE temp145.
    temp146-f000001 = `AA`.
    temp146-f000002 = 3.
    INSERT temp146 INTO TABLE temp145.
    lt_exp = temp145.
    cl_abap_unit_assert=>assert_equals( act = lt_data
                                        exp = lt_exp ).

  ENDMETHOD.

  METHOD union_order_by_unknown.
        DATA temp147 TYPE z2ui5_cl_sql_query=>ty_t_fieldlist.
        DATA temp148 LIKE LINE OF temp147.

    TRY.

        CLEAR temp147.

        temp148-field = `F000001`.
        temp148-ref_field = `CARRID`.
        INSERT temp148 INTO TABLE temp147.
        z2ui5_cl_sql_query=>get_order( order_by     = `CONNID`
                                       it_fieldlist = temp147 ).
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
        DATA lx TYPE REF TO z2ui5_cx_sql_error.

    TRY.
        z2ui5_cl_sql_context=>xml_srtti_parse( val ).
        cl_abap_unit_assert=>fail( `the document must be refused` ).

      CATCH z2ui5_cx_sql_error INTO lx.
        " by the class check - not by a transformation that already ran
        cl_abap_unit_assert=>assert_char_cp( act = lx->get_text( )
                                             exp = `*not part of S-RTTI*` ).
    ENDTRY.

  ENDMETHOD.

  METHOD round_trip.

    DATA temp149 TYPE string_table.
    DATA lt_data LIKE temp149.
    DATA lr_back TYPE REF TO data.
    FIELD-SYMBOLS <back> TYPE string_table.
    CLEAR temp149.
    INSERT `A` INTO TABLE temp149.
    INSERT `B` INTO TABLE temp149.

    lt_data = temp149.


    lr_back = z2ui5_cl_sql_context=>xml_srtti_parse(
        z2ui5_cl_sql_context=>xml_srtti_stringify( lt_data ) ).


    ASSIGN lr_back->* TO <back>.
    cl_abap_unit_assert=>assert_equals( exp = lt_data
                                        act = <back> ).

  ENDMETHOD.

  METHOD refuses_other_class.

    " the same document, its S-RTTI objects named as objects of another class
    DATA lo_srtti TYPE REF TO z2ui5_cl_srt_typedescr.
    DATA temp151 TYPE REF TO cl_abap_refdescr.
    DATA lo_ref LIKE temp151.
    DATA lv_class TYPE string.
    DATA lv_prefix TYPE string.
    DATA temp152 TYPE string_table.
    DATA lv_xml TYPE string.
    temp151 ?= cl_abap_typedescr=>describe_by_data( lo_srtti ).

    lo_ref = temp151.

    lv_class = lo_ref->get_referenced_type( )->get_relative_name( ).

    lv_prefix = substring( val = lv_class
                                 len = strlen( lv_class ) - strlen( `TYPEDESCR` ) ).


    CLEAR temp152.
    INSERT `A` INTO TABLE temp152.

    lv_xml = z2ui5_cl_sql_context=>xml_srtti_stringify( temp152 ).
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

"! The history store (z2ui5_cl_sql_history_api) - here, beside the other
"! tests, because the API class has no test include. It writes the history
"! of the current user: setup keeps that user's rows, teardown puts them
"! back
CLASS ltcl_history DEFINITION FINAL FOR TESTING
  DURATION MEDIUM
  RISK LEVEL DANGEROUS.

  PRIVATE SECTION.
    DATA mt_saved TYPE z2ui5_cl_sql_db=>ty_t_db.

    METHODS setup.
    METHODS teardown.

    METHODS list_without_result FOR TESTING RAISING cx_static_check.
    METHODS reads_single_document FOR TESTING RAISING cx_static_check.
    METHODS keeps_newest_entries FOR TESTING RAISING cx_static_check.
    METHODS delete_removes_all FOR TESTING RAISING cx_static_check.

    METHODS entry
      IMPORTING
        val           TYPE i
      RETURNING
        VALUE(result) TYPE z2ui5_cl_sql_history_api=>ty_s_entry.

ENDCLASS.


CLASS ltcl_history IMPLEMENTATION.

  METHOD setup.

    mt_saved = z2ui5_cl_sql_db=>load_multi_by_handle( uname  = sy-uname
                                                       handle = z2ui5_cl_sql_history_api=>c_handle_history ).
    z2ui5_cl_sql_history_api=>db_delete( ).

  ENDMETHOD.

  METHOD teardown.

    z2ui5_cl_sql_history_api=>db_delete( ).
    IF mt_saved IS NOT INITIAL.
      MODIFY z2ui5_t_33 FROM TABLE mt_saved.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.

  METHOD entry.

    CLEAR result.
    result-uuid = |LTCL_HISTORY_{ val }|.
    result-timestampl = 20260101000000 + val.
    result-tabname = `T100`.
    result-counter = `1`.
    result-sql_command = |SELECT * FROM T100 -- { val }|.
    result-result_data = |RESULT { val }|.

  ENDMETHOD.

  METHOD list_without_result.

    DATA ls_entry TYPE z2ui5_cl_sql_history_api=>ty_s_entry.
    DATA lt_list TYPE z2ui5_cl_sql_history_api=>ty_t_entry.
    FIELD-SYMBOLS <temp154> LIKE LINE OF lt_list.
    DATA temp155 LIKE sy-tabix.
    FIELD-SYMBOLS <temp156> LIKE LINE OF lt_list.
    DATA temp157 LIKE sy-tabix.
    ls_entry = entry( 1 ).
    z2ui5_cl_sql_history_api=>db_create( ls_entry ).


    lt_list = z2ui5_cl_sql_history_api=>db_read_multi_by_user( ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_list ) ).


    temp155 = sy-tabix.
    READ TABLE lt_list INDEX 1 ASSIGNING <temp154>.
    sy-tabix = temp155.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = ls_entry-sql_command
                                        act = <temp154>-sql_command ).


    temp157 = sy-tabix.
    READ TABLE lt_list INDEX 1 ASSIGNING <temp156>.
    sy-tabix = temp157.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp156>-result_data ).

    cl_abap_unit_assert=>assert_equals(
        exp = ls_entry-result_data
        act = z2ui5_cl_sql_history_api=>db_read_by_id( ls_entry-uuid )-result_data ).

  ENDMETHOD.

  METHOD reads_single_document.

    " an entry written before the result got a document of its own
    DATA ls_entry TYPE z2ui5_cl_sql_history_api=>ty_s_entry.
    DATA lt_list TYPE z2ui5_cl_sql_history_api=>ty_t_entry.
    FIELD-SYMBOLS <temp158> LIKE LINE OF lt_list.
    DATA temp159 LIKE sy-tabix.
    ls_entry = entry( 2 ).
    ls_entry-uname = sy-uname.
    z2ui5_cl_sql_db=>save( uname   = sy-uname
                            handle  = z2ui5_cl_sql_history_api=>c_handle_history
                            handle2 = ls_entry-uuid
                            data    = ls_entry ).


    lt_list = z2ui5_cl_sql_history_api=>db_read_multi_by_user( ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_list ) ).


    temp159 = sy-tabix.
    READ TABLE lt_list INDEX 1 ASSIGNING <temp158>.
    sy-tabix = temp159.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    cl_abap_unit_assert=>assert_initial( <temp158>-result_data ).

    cl_abap_unit_assert=>assert_equals(
        exp = ls_entry-result_data
        act = z2ui5_cl_sql_history_api=>db_read_by_id( ls_entry-uuid )-result_data ).

  ENDMETHOD.

  METHOD keeps_newest_entries.

    DATA lv_count TYPE i.
    DATA lt_list TYPE z2ui5_cl_sql_history_api=>ty_t_entry.
    DATA lv_oldest TYPE z2ui5_cl_sql_history_api=>ty_s_entry-uuid.
    DATA lv_newest TYPE z2ui5_cl_sql_history_api=>ty_s_entry-uuid.
    DATA temp1 TYPE xsdboolean.
    DATA temp3 LIKE sy-subrc.
    DATA temp2 TYPE xsdboolean.
    DATA temp4 LIKE sy-subrc.
    lv_count = z2ui5_cl_sql_history_api=>c_history_max + 1.
    DO lv_count TIMES.
      z2ui5_cl_sql_history_api=>db_create( entry( sy-index ) ).
    ENDDO.


    lt_list = z2ui5_cl_sql_history_api=>db_read_multi_by_user( ).
    cl_abap_unit_assert=>assert_equals( exp = z2ui5_cl_sql_history_api=>c_history_max
                                        act = lines( lt_list ) ).
    " the oldest went, with its result

    lv_oldest = entry( 1 )-uuid.

    lv_newest = entry( lv_count )-uuid.


    READ TABLE lt_list WITH KEY uuid = lv_oldest TRANSPORTING NO FIELDS.
    temp3 = sy-subrc.
    temp1 = boolc( temp3 = 0 ).
    cl_abap_unit_assert=>assert_false( temp1 ).
    cl_abap_unit_assert=>assert_initial( z2ui5_cl_sql_history_api=>db_read_by_id( lv_oldest ) ).


    READ TABLE lt_list WITH KEY uuid = lv_newest TRANSPORTING NO FIELDS.
    temp4 = sy-subrc.
    temp2 = boolc( temp4 = 0 ).
    cl_abap_unit_assert=>assert_true( temp2 ).

  ENDMETHOD.

  METHOD delete_removes_all.

    z2ui5_cl_sql_history_api=>db_create( entry( 3 ) ).
    z2ui5_cl_sql_history_api=>db_delete( ).

    cl_abap_unit_assert=>assert_initial(
        z2ui5_cl_sql_db=>load_multi_by_handle( uname  = sy-uname
                                                handle = z2ui5_cl_sql_history_api=>c_handle_history ) ).

  ENDMETHOD.

ENDCLASS.
