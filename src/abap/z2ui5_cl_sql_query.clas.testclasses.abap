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

ENDCLASS.
