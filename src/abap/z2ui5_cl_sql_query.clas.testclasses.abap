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

ENDCLASS.
