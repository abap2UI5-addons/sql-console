CLASS z2ui5_cl_sql_query DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_s_field,
        field     TYPE string,
        ref_table TYPE string,
        ref_field TYPE string,
      END OF ty_s_field.
    TYPES ty_t_fieldlist TYPE STANDARD TABLE OF ty_s_field WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_source,
        name  TYPE string,
        alias TYPE string,
      END OF ty_s_source.
    TYPES ty_t_source TYPE STANDARD TABLE OF ty_s_source WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_clauses,
        select_list TYPE string,
        from        TYPE string,
        where       TYPE string,
        group_by    TYPE string,
        having      TYPE string,
        order_by    TYPE string,
        rows        TYPE i,
        distinct    TYPE abap_bool,
      END OF ty_s_clauses.
    TYPES ty_t_clauses TYPE STANDARD TABLE OF ty_s_clauses WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_result,
        data      TYPE REF TO data,
        fieldlist TYPE ty_t_fieldlist,
        tabname   TYPE string,
        from      TYPE string,
        query     TYPE string,
        count     TYPE i,
      END OF ty_s_result.

    CLASS-METHODS run
      IMPORTING
        query         TYPE clike
        max_rows      TYPE i DEFAULT 500
      RETURNING
        VALUE(result) TYPE ty_s_result
      RAISING
        z2ui5_cx_sql_error.

    CLASS-METHODS normalize
      IMPORTING
        query         TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS parse
      IMPORTING
        query         TYPE clike
        max_rows      TYPE i DEFAULT 0
      RETURNING
        VALUE(result) TYPE ty_t_clauses
      RAISING
        z2ui5_cx_sql_error.

    CLASS-METHODS get_sources
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE ty_t_source.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_item,
        text  TYPE string,
        kind  TYPE string,
        agg   TYPE string,
        inner TYPE string,
        alias TYPE string,
      END OF ty_s_item.
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH DEFAULT KEY.

    TYPES:
      BEGIN OF ty_s_target,
        select_list TYPE string,
        o_table     TYPE REF TO cl_abap_tabledescr,
        fieldlist   TYPE ty_t_fieldlist,
      END OF ty_s_target.

    CLASS-METHODS parse_segment
      IMPORTING
        val           TYPE string
        max_rows      TYPE i
      RETURNING
        VALUE(result) TYPE ty_s_clauses
      RAISING
        z2ui5_cx_sql_error.

    CLASS-METHODS get_items
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE ty_t_item.

    CLASS-METHODS build_target
      IMPORTING
        is_clauses    TYPE ty_s_clauses
      RETURNING
        VALUE(result) TYPE ty_s_target
      RAISING
        z2ui5_cx_sql_error.

    CLASS-METHODS resolve_field
      IMPORTING
        it_source TYPE ty_t_source
        val       TYPE clike
      EXPORTING
        eo_type   TYPE REF TO cl_abap_datadescr
        ev_table  TYPE string
        ev_field  TYPE string
      RAISING
        z2ui5_cx_sql_error.

    CLASS-METHODS get_struct_by_name
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO cl_abap_structdescr
      RAISING
        z2ui5_cx_sql_error.

    CLASS-METHODS append_field
      IMPORTING
        io_type      TYPE REF TO cl_abap_datadescr
        ref_table    TYPE string
        ref_field    TYPE string
      CHANGING
        ct_comp      TYPE cl_abap_structdescr=>component_table
        ct_fieldlist TYPE ty_t_fieldlist.

    CLASS-METHODS join_by_comma
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS join_order_by
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! Splits SQL text into its literals and the text between them: the
    "! odd lines are text outside literals, the even lines are literals
    "! ('...' or `...`, a doubled delimiter is an escaped one) with their delimiters
    CLASS-METHODS split_literals
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string_table.

    CLASS-METHODS upper_outside_literals
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! The same text with every literal blanked out by underscores, delimiters
    "! included - same length, so an offset found in it is valid in the original
    CLASS-METHODS mask_literals
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! condense( ), but blanks inside a literal are kept as they are
    CLASS-METHODS condense_outside_literals
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string.

    "! The tokens of SQL text, separated by blanks and commas outside literals
    CLASS-METHODS tokenize
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE string_table.

    CLASS-METHODS select_into
      IMPORTING
        is_clauses  TYPE ty_s_clauses
        select_list TYPE string
      CHANGING
        ct_data     TYPE STANDARD TABLE
      RAISING
        z2ui5_cx_sql_error.

ENDCLASS.


CLASS z2ui5_cl_sql_query IMPLEMENTATION.

  METHOD run.

    FIELD-SYMBOLS <lt_result> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <lt_part>   TYPE STANDARD TABLE.
    DATA lr_part TYPE REF TO data.

    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    DATA ls_first LIKE LINE OF lt_clauses.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_clauses.
    DATA temp4 LIKE sy-tabix.
    DATA ls_target TYPE z2ui5_cl_sql_query=>ty_s_target.
    DATA temp117 LIKE LINE OF lt_clauses.
    DATA lr_clauses LIKE REF TO temp117.
      DATA ls_target2 TYPE z2ui5_cl_sql_query=>ty_s_target.
    DATA lt_source TYPE z2ui5_cl_sql_query=>ty_t_source.
    DATA temp118 TYPE z2ui5_cl_sql_query=>ty_s_result-tabname.
    DATA temp119 TYPE z2ui5_cl_sql_query=>ty_s_source.
    lt_clauses = parse( query    = query
                              max_rows = max_rows ).




    temp4 = sy-tabix.
    READ TABLE lt_clauses INDEX 1 ASSIGNING <temp3>.
    sy-tabix = temp4.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_first = <temp3>.

    ls_target = build_target( ls_first ).

    CREATE DATA result-data TYPE HANDLE ls_target-o_table.
    ASSIGN result-data->* TO <lt_result>.

    select_into( EXPORTING is_clauses  = ls_first
                           select_list = ls_target-select_list
                 CHANGING  ct_data     = <lt_result> ).

    " union segments are executed separately and appended to the
    " result of the first segment, converted to its line type


    LOOP AT lt_clauses REFERENCE INTO lr_clauses FROM 2.


      ls_target2 = build_target( lr_clauses->* ).
      CREATE DATA lr_part TYPE HANDLE ls_target-o_table.
      ASSIGN lr_part->* TO <lt_part>.

      select_into( EXPORTING is_clauses  = lr_clauses->*
                             select_list = ls_target2-select_list
                   CHANGING  ct_data     = <lt_part> ).

      APPEND LINES OF <lt_part> TO <lt_result>.

    ENDLOOP.


    lt_source = get_sources( ls_first-from ).
    result-fieldlist = ls_target-fieldlist.

    CLEAR temp118.

    READ TABLE lt_source INTO temp119 INDEX 1.
    IF sy-subrc = 0.
      temp118 = temp119-name.
    ENDIF.
    result-tabname   = temp118.
    result-from      = ls_first-from.
    result-query     = normalize( query ).
    result-count     = lines( <lt_result> ).

  ENDMETHOD.

  METHOD normalize.

    DATA temp120 TYPE string.
    DATA lv_query TYPE string.
    TYPES temp1 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_line TYPE temp1.
    DATA temp121 LIKE LINE OF lt_line.
    DATA lr_line LIKE REF TO temp121.
    temp120 = query.

    lv_query = replace( val  = temp120
                              sub  = cl_abap_char_utilities=>cr_lf
                              with = cl_abap_char_utilities=>newline
                              occ  = 0 ).



    SPLIT lv_query AT cl_abap_char_utilities=>newline INTO TABLE lt_line.


    LOOP AT lt_line REFERENCE INTO lr_line.
      lr_line->* = condense_outside_literals( lr_line->* ).
    ENDLOOP.
    DELETE lt_line WHERE table_line IS INITIAL.

    result = concat_lines_of( table = lt_line
                              sep   = ` ` ).

  ENDMETHOD.

  METHOD parse.

    DATA lt_segment TYPE string_table.
    DATA lv_query TYPE string.
    DATA lv_mask TYPE string.
      DATA lv_offset TYPE i.
    DATA temp122 LIKE LINE OF lt_segment.
    DATA lr_segment LIKE REF TO temp122.
    lv_query = normalize( query ).
    " keywords are searched in the masked copy, so a literal never splits the query

    lv_mask = mask_literals( lv_query ).

    DO.

      FIND FIRST OCCURRENCE OF ` UNION SELECT ` IN lv_mask IGNORING CASE MATCH OFFSET lv_offset.
      IF sy-subrc <> 0.
        INSERT lv_query INTO TABLE lt_segment.
        EXIT.
      ENDIF.
      INSERT lv_query(lv_offset) INTO TABLE lt_segment.
      lv_offset = lv_offset + 7.
      lv_query = lv_query+lv_offset.
      lv_mask = lv_mask+lv_offset.
    ENDDO.



    LOOP AT lt_segment REFERENCE INTO lr_segment.
      INSERT parse_segment( val      = lr_segment->*
                            max_rows = max_rows ) INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD parse_segment.

    TYPES:
      BEGIN OF ty_s_pos,
        keyword TYPE string,
        offset  TYPE i,
        length  TYPE i,
      END OF ty_s_pos.
    TYPES temp2 TYPE STANDARD TABLE OF ty_s_pos WITH DEFAULT KEY.
DATA lt_pos TYPE temp2.
    DATA lv_rows TYPE string.
    DATA lv_match_offset TYPE i.
    DATA lv_match_length TYPE i.

    DATA lv_segment LIKE val.
    DATA lv_mask TYPE string.
    DATA lv_select_offset TYPE i.
    DATA lv_from_offset TYPE i.
    DATA lv_select_start TYPE i.
    DATA lv_length TYPE i.
    DATA lv_select TYPE string.
    DATA lv_rest_offset TYPE i.
    DATA lv_rest TYPE string.
    DATA lv_rest_mask TYPE string.
    DATA temp5 TYPE string_table.
    DATA temp123 LIKE temp5.
    DATA temp7 LIKE LINE OF temp123.
    DATA lr_keyword LIKE REF TO temp7.
      DATA lv_offset TYPE i.
        DATA temp124 TYPE ty_s_pos.
    DATA lv_from_length TYPE ty_s_pos-offset.
    FIELD-SYMBOLS <temp8> LIKE LINE OF lt_pos.
    DATA temp9 LIKE sy-tabix.
    DATA lv_from TYPE string.
    DATA temp125 LIKE LINE OF lt_pos.
    DATA lr_pos LIKE REF TO temp125.
      DATA lv_content_offset TYPE ty_s_pos-offset.
      DATA lv_index TYPE i.
      DATA temp126 LIKE sy-subrc.
      DATA temp127 LIKE sy-tabix.
        DATA lv_content_length TYPE ty_s_pos-offset.
        FIELD-SYMBOLS <temp10> LIKE LINE OF lt_pos.
        DATA temp11 LIKE sy-tabix.
        DATA lv_content TYPE string.
    lv_segment = val.
    " every keyword is searched in the masked copy and cut out of both, so
    " the offsets stay aligned and a keyword inside a literal is never found

    lv_mask = mask_literals( lv_segment ).

    FIND FIRST OCCURRENCE OF REGEX `UP TO ([0-9]+) ROWS` IN lv_mask IGNORING CASE
         MATCH OFFSET lv_match_offset MATCH LENGTH lv_match_length SUBMATCHES lv_rows.
    IF sy-subrc = 0.
      result-rows = lv_rows.
      lv_segment = replace( val = lv_segment
                            off = lv_match_offset
                            len = lv_match_length
                            with = `` ).
      lv_mask = replace( val = lv_mask
                         off = lv_match_offset
                         len = lv_match_length
                         with = `` ).
    ELSE.
      result-rows = max_rows.
    ENDIF.

    FIND FIRST OCCURRENCE OF REGEX `(INTO|APPENDING)( TABLE| CORRESPONDING FIELDS OF TABLE| CORRESPONDING FIELDS OF)? @?\S+`
         IN lv_mask IGNORING CASE MATCH OFFSET lv_match_offset MATCH LENGTH lv_match_length.
    IF sy-subrc = 0.
      lv_segment = replace( val = lv_segment
                            off = lv_match_offset
                            len = lv_match_length
                            with = `` ).
      lv_mask = replace( val = lv_mask
                         off = lv_match_offset
                         len = lv_match_length
                         with = `` ).
    ENDIF.


    FIND FIRST OCCURRENCE OF `SELECT ` IN lv_mask IGNORING CASE MATCH OFFSET lv_select_offset.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no SELECT found in query`.
    ENDIF.


    FIND FIRST OCCURRENCE OF ` FROM ` IN SECTION OFFSET lv_select_offset OF lv_mask
         IGNORING CASE MATCH OFFSET lv_from_offset.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no FROM found in query`.
    ENDIF.


    lv_select_start = lv_select_offset + 7.

    lv_length = lv_from_offset - lv_select_start.
    IF lv_length <= 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `SQL_PARSER_ERROR - empty select list`.
    ENDIF.


    lv_select = substring( val = lv_segment
                                 off = lv_select_start
                                 len = lv_length ).
    lv_select = condense_outside_literals( upper_outside_literals( lv_select ) ).
    IF strlen( lv_select ) > 7 AND lv_select(7) = `SINGLE `.
      result-rows = 1.
      lv_select = condense_outside_literals( substring( val = lv_select
                                                     off = 7 ) ).
    ENDIF.
    IF strlen( lv_select ) > 9 AND lv_select(9) = `DISTINCT `.
      result-distinct = abap_true.
      lv_select = condense_outside_literals( substring( val = lv_select
                                                     off = 9 ) ).
    ENDIF.
    result-select_list = lv_select.


    lv_rest_offset = lv_from_offset + 6.

    lv_rest = lv_segment+lv_rest_offset.

    lv_rest_mask = lv_mask+lv_rest_offset.


    CLEAR temp5.
    INSERT ` WHERE ` INTO TABLE temp5.
    INSERT ` GROUP BY ` INTO TABLE temp5.
    INSERT ` HAVING ` INTO TABLE temp5.
    INSERT ` ORDER BY ` INTO TABLE temp5.

    temp123 = temp5.


    LOOP AT temp123
         REFERENCE INTO lr_keyword.

      FIND FIRST OCCURRENCE OF lr_keyword->* IN lv_rest_mask IGNORING CASE MATCH OFFSET lv_offset.
      IF sy-subrc = 0.

        CLEAR temp124.
        temp124-keyword = condense( lr_keyword->* ).
        temp124-offset = lv_offset.
        temp124-length = strlen( lr_keyword->* ).
        INSERT temp124 INTO TABLE lt_pos.
      ENDIF.
    ENDLOOP.
    SORT lt_pos BY offset.

    IF lt_pos IS INITIAL.
      result-from = condense_outside_literals( upper_outside_literals( lv_rest ) ).
      RETURN.
    ENDIF.




    temp9 = sy-tabix.
    READ TABLE lt_pos INDEX 1 ASSIGNING <temp8>.
    sy-tabix = temp9.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    lv_from_length = <temp8>-offset.

    lv_from = substring( val = lv_rest
                               len = lv_from_length ).
    result-from = condense_outside_literals( upper_outside_literals( lv_from ) ).



    LOOP AT lt_pos REFERENCE INTO lr_pos.

      lv_content_offset = lr_pos->offset + lr_pos->length.

      lv_index = sy-tabix + 1.


      temp127 = sy-tabix.
      READ TABLE lt_pos INDEX lv_index TRANSPORTING NO FIELDS.
      temp126 = sy-subrc.
      sy-tabix = temp127.
      IF temp126 = 0.



        temp11 = sy-tabix.
        READ TABLE lt_pos INDEX lv_index ASSIGNING <temp10>.
        sy-tabix = temp11.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        lv_content_length = <temp10>-offset - lv_content_offset.

        lv_content = lv_rest+lv_content_offset(lv_content_length).
      ELSE.
        lv_content = lv_rest+lv_content_offset.
      ENDIF.
      lv_content = condense_outside_literals( lv_content ).

      CASE lr_pos->keyword.
        WHEN `WHERE`.
          result-where = lv_content.
        WHEN `GROUP BY`.
          result-group_by = join_by_comma( upper_outside_literals( lv_content ) ).
        WHEN `HAVING`.
          result-having = lv_content.
        WHEN `ORDER BY`.
          result-order_by = join_order_by( upper_outside_literals( lv_content ) ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD join_by_comma.

    DATA lt_token TYPE string_table.
    lt_token = tokenize( val ).
    result = concat_lines_of( table = lt_token
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD join_order_by.

    DATA lt_item TYPE string_table.

    DATA lt_token TYPE string_table.
    DATA temp128 LIKE LINE OF lt_token.
    DATA lr_token LIKE REF TO temp128.
      DATA lv_last TYPE i.
      DATA temp129 TYPE string.
      DATA temp130 TYPE string.
        FIELD-SYMBOLS <temp131> LIKE LINE OF lt_item.
        DATA temp132 LIKE sy-tabix.
        FIELD-SYMBOLS <temp12> LIKE LINE OF lt_item.
        DATA temp13 LIKE sy-tabix.
      DATA temp133 LIKE LINE OF lt_item.
    lt_token = tokenize( val ).



    LOOP AT lt_token REFERENCE INTO lr_token.


      lv_last = lines( lt_item ).
      " OPTIONAL, not a plain table expression: the 7.02 downport reads a
      " table expression before the IF, the guard lv_last > 0 or not

      CLEAR temp129.

      READ TABLE lt_item INTO temp130 INDEX lv_last.
      IF sy-subrc = 0.
        temp129 = temp130.
      ENDIF.
      IF lv_last > 0
         AND (    lr_token->* = `ASCENDING`
               OR lr_token->* = `DESCENDING`
               OR ( lr_token->* = `KEY` AND temp129 = `PRIMARY` ) ).


        temp132 = sy-tabix.
        READ TABLE lt_item INDEX lv_last ASSIGNING <temp131>.
        sy-tabix = temp132.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp13 = sy-tabix.
        READ TABLE lt_item INDEX lv_last ASSIGNING <temp12>.
        sy-tabix = temp13.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp131> = |{ <temp12> } { lr_token->* }|.
        CONTINUE.
      ENDIF.


      temp133 = lr_token->*.
      INSERT temp133 INTO TABLE lt_item.

    ENDLOOP.

    result = concat_lines_of( table = lt_item
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD get_sources.

    DATA ls_source TYPE ty_s_source.
    DATA lv_state TYPE string.
    DATA lt_token TYPE string_table.
    DATA temp134 LIKE LINE OF lt_token.
    DATA lr_token LIKE REF TO temp134.
      DATA lv_token TYPE string.
      DATA lv_check_join TYPE abap_bool.
      DATA temp1 TYPE xsdboolean.
            DATA lv_last TYPE i.
            FIELD-SYMBOLS <temp135> LIKE LINE OF result.
            DATA temp136 LIKE sy-tabix.
          FIELD-SYMBOLS <temp137> LIKE LINE OF result.
          DATA temp138 LIKE sy-tabix.
    lv_state = `SOURCE`.


    lt_token = tokenize( upper_outside_literals( val ) ).



    LOOP AT lt_token REFERENCE INTO lr_token.


      lv_token = lr_token->*.


      temp1 = boolc( lv_token = `JOIN` OR lv_token = `INNER` OR lv_token = `LEFT` OR lv_token = `RIGHT` OR lv_token = `OUTER` OR lv_token = `CROSS` ).
      lv_check_join = temp1.

      CASE lv_state.

        WHEN `SOURCE`.
          IF lv_check_join = abap_true.
            CONTINUE.
          ENDIF.
          ls_source-name = lv_token.
          ls_source-alias = lv_token.
          INSERT ls_source INTO TABLE result.
          lv_state = `AFTER_SOURCE`.

        WHEN `AFTER_SOURCE`.
          IF lv_token = `AS`.
            lv_state = `ALIAS`.
          ELSEIF lv_token = `ON`.
            lv_state = `ON`.
          ELSEIF lv_check_join = abap_true.
            lv_state = `SOURCE`.
          ELSE.

            lv_last = lines( result ).


            temp136 = sy-tabix.
            READ TABLE result INDEX lv_last ASSIGNING <temp135>.
            sy-tabix = temp136.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp135>-alias = lv_token.
          ENDIF.

        WHEN `ALIAS`.
          lv_last = lines( result ).


          temp138 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp137>.
          sy-tabix = temp138.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp137>-alias = lv_token.
          lv_state = `AFTER_SOURCE`.

        WHEN `ON`.
          IF lv_check_join = abap_true.
            lv_state = `SOURCE`.
          ENDIF.

      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_items.

    DATA ls_item TYPE ty_s_item.

    DATA lt_token TYPE string_table.
    DATA lv_index TYPE i.
      DATA lv_token LIKE LINE OF lt_token.
      FIELD-SYMBOLS <temp14> LIKE LINE OF lt_token.
      DATA temp15 LIKE sy-tabix.
        DATA lv_last TYPE i.
          FIELD-SYMBOLS <temp139> LIKE LINE OF result.
          DATA temp140 LIKE sy-tabix.
          FIELD-SYMBOLS <temp16> LIKE LINE OF lt_token.
          DATA temp17 LIKE sy-tabix.
          FIELD-SYMBOLS <temp141> LIKE LINE OF result.
          DATA temp142 LIKE sy-tabix.
          FIELD-SYMBOLS <temp18> LIKE LINE OF result.
          DATA temp19 LIKE sy-tabix.
          FIELD-SYMBOLS <temp1> LIKE LINE OF lt_token.
          DATA temp2 LIKE sy-tabix.
          DATA lv_part LIKE LINE OF lt_token.
          FIELD-SYMBOLS <temp20> LIKE LINE OF lt_token.
          DATA temp21 LIKE sy-tabix.
        DATA lv_head TYPE string.
        DATA lv_inner TYPE string.
            FIELD-SYMBOLS <temp143> LIKE LINE OF lt_token.
            DATA temp144 LIKE sy-tabix.
            FIELD-SYMBOLS <temp145> LIKE LINE OF lt_token.
            DATA temp146 LIKE sy-tabix.
          DATA lv_dummy TYPE string.
    lt_token = tokenize( val ).


    lv_index = 0.
    WHILE lv_index < lines( lt_token ).

      lv_index = lv_index + 1.



      temp15 = sy-tabix.
      READ TABLE lt_token INDEX lv_index ASSIGNING <temp14>.
      sy-tabix = temp15.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_token = <temp14>.

      IF lv_token = `AS`.
        lv_index = lv_index + 1.

        lv_last = lines( result ).
        IF lv_index <= lines( lt_token ) AND lv_last > 0.


          temp140 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp139>.
          sy-tabix = temp140.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp17 = sy-tabix.
          READ TABLE lt_token INDEX lv_index ASSIGNING <temp16>.
          sy-tabix = temp17.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp139>-alias = <temp16>.


          temp142 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp141>.
          sy-tabix = temp142.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp19 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp18>.
          sy-tabix = temp19.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp2 = sy-tabix.
          READ TABLE lt_token INDEX lv_index ASSIGNING <temp1>.
          sy-tabix = temp2.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp141>-text = |{ <temp18>-text } AS { <temp1> }|.
        ENDIF.
        CONTINUE.
      ENDIF.

      CLEAR ls_item.

      IF lv_token = `CASE`.
        ls_item-kind = `CASE`.
        ls_item-text = lv_token.
        WHILE lv_index < lines( lt_token ).
          lv_index = lv_index + 1.



          temp21 = sy-tabix.
          READ TABLE lt_token INDEX lv_index ASSIGNING <temp20>.
          sy-tabix = temp21.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          lv_part = <temp20>.
          ls_item-text = |{ ls_item-text } { lv_part }|.
          IF lv_part = `END`.
            EXIT.
          ENDIF.
        ENDWHILE.
        INSERT ls_item INTO TABLE result.
        CONTINUE.
      ENDIF.

      IF lv_token CS `(`.


        SPLIT lv_token AT `(` INTO lv_head lv_inner.
        IF lv_head = `COUNT` OR lv_head = `AVG` OR lv_head = `SUM` OR lv_head = `MIN` OR lv_head = `MAX`.
          ls_item-kind = `AGG`.
          ls_item-agg = lv_head.
          ls_item-text = lv_token.
          WHILE ls_item-text NS `)` AND lv_index < lines( lt_token ).
            lv_index = lv_index + 1.


            temp144 = sy-tabix.
            READ TABLE lt_token INDEX lv_index ASSIGNING <temp143>.
            sy-tabix = temp144.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            ls_item-text = |{ ls_item-text } { <temp143> }|.


            temp146 = sy-tabix.
            READ TABLE lt_token INDEX lv_index ASSIGNING <temp145>.
            sy-tabix = temp146.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            lv_inner = |{ lv_inner } { <temp145> }|.
          ENDWHILE.

          SPLIT lv_inner AT `)` INTO lv_inner lv_dummy.
          ls_item-inner = condense( lv_inner ).
          INSERT ls_item INTO TABLE result.
          CONTINUE.
        ENDIF.
      ENDIF.

      ls_item-kind = `FIELD`.
      ls_item-text = lv_token.
      INSERT ls_item INTO TABLE result.

    ENDWHILE.

  ENDMETHOD.

  METHOD build_target.

    DATA lt_comp TYPE cl_abap_structdescr=>component_table.
    DATA lt_part TYPE string_table.
    DATA lo_type TYPE REF TO cl_abap_datadescr.
    DATA lv_table TYPE string.
    DATA lv_field TYPE string.

    DATA lt_source TYPE z2ui5_cl_sql_query=>ty_t_source.
    DATA temp147 TYPE z2ui5_cl_sql_query=>ty_t_item.
    DATA temp22 LIKE LINE OF temp147.
    DATA lr_item LIKE REF TO temp22.
          DATA temp148 TYPE string.
          DATA temp149 TYPE string.
          DATA lv_prefix TYPE string.
          DATA lv_name TYPE string.
          DATA lv_dummy TYPE string.
            DATA temp150 LIKE LINE OF lt_source.
            DATA lr_source LIKE REF TO temp150.
              DATA lo_struct TYPE REF TO cl_abap_structdescr.
              DATA temp151 LIKE LINE OF lo_struct->components.
              DATA lr_comp LIKE REF TO temp151.
                DATA temp152 TYPE string.
                DATA temp153 LIKE LINE OF lt_part.
            DATA temp154 TYPE string.
            DATA temp155 TYPE string.
        DATA lo_line TYPE REF TO cl_abap_structdescr.
        DATA lx_error TYPE REF TO cx_root.
    lt_source = get_sources( is_clauses-from ).
    IF lt_source IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no data source found in FROM clause`.
    ENDIF.


    temp147 = get_items( is_clauses-select_list ).


    LOOP AT temp147 REFERENCE INTO lr_item.

      CASE lr_item->kind.

        WHEN `CASE`.

          IF lr_item->alias IS NOT INITIAL.
            temp148 = lr_item->alias.
          ELSE.
            temp148 = `CASE`.
          ENDIF.
          append_field( EXPORTING io_type      = cl_abap_elemdescr=>get_string( )
                                  ref_table    = ``
                                  ref_field    = temp148
                        CHANGING  ct_comp      = lt_comp
                                  ct_fieldlist = result-fieldlist ).
          INSERT lr_item->text INTO TABLE lt_part.

        WHEN `AGG`.
          CASE lr_item->agg.
            WHEN `COUNT`.
              lo_type = cl_abap_elemdescr=>get_i( ).
              lv_field = `COUNT`.
            WHEN `AVG`.
              lo_type = cl_abap_elemdescr=>get_f( ).
              " the column is named after the field - AVG( DISTINCT a~netwr )
              " gives NETWR, as MIN, MAX and SUM do through resolve_field
              lv_field = to_upper( condense( lr_item->inner ) ).
              IF strlen( lv_field ) > 9 AND lv_field(9) = `DISTINCT `.
                lv_field = condense( lv_field+9 ).
              ENDIF.
              IF lv_field CS `~`.
                lv_field = substring_after( val = lv_field
                                            sub = `~` ).
              ENDIF.
            WHEN OTHERS.
              resolve_field( EXPORTING it_source = lt_source
                                       val       = lr_item->inner
                             IMPORTING eo_type   = lo_type
                                       ev_field  = lv_field ).
          ENDCASE.

          IF lr_item->alias IS NOT INITIAL.
            temp149 = lr_item->alias.
          ELSE.
            temp149 = lv_field.
          ENDIF.
          append_field( EXPORTING io_type      = lo_type
                                  ref_table    = ``
                                  ref_field    = temp149
                        CHANGING  ct_comp      = lt_comp
                                  ct_fieldlist = result-fieldlist ).
          INSERT lr_item->text INTO TABLE lt_part.

        WHEN `FIELD`.



          SPLIT lr_item->text AT `~` INTO lv_prefix lv_name.
          IF lv_name IS INITIAL.
            lv_name = lv_prefix.
            CLEAR lv_prefix.
          ENDIF.
          " strip a trailing ` AS alias` from the field part - with or
          " without a table prefix, `carrid AS c` is the field CARRID

          SPLIT lv_name AT ` ` INTO lv_name lv_dummy.

          IF lv_name = `*`.



            LOOP AT lt_source REFERENCE INTO lr_source.
              IF lv_prefix IS NOT INITIAL AND lr_source->alias <> lv_prefix AND lr_source->name <> lv_prefix.
                CONTINUE.
              ENDIF.

              lo_struct = get_struct_by_name( lr_source->name ).


              LOOP AT lo_struct->components REFERENCE INTO lr_comp.

                temp152 = lr_comp->name.
                append_field( EXPORTING io_type      = lo_struct->get_component_type( lr_comp->name )
                                        ref_table    = lr_source->name
                                        ref_field    = temp152
                              CHANGING  ct_comp      = lt_comp
                                        ct_fieldlist = result-fieldlist ).

                temp153 = |{ lr_source->alias }~{ lr_comp->name }|.
                INSERT temp153 INTO TABLE lt_part.
              ENDLOOP.
            ENDLOOP.

          ELSE.


            IF lv_prefix IS NOT INITIAL.
              temp154 = |{ lv_prefix }~{ lv_name }|.
            ELSE.
              temp154 = lv_name.
            ENDIF.
            resolve_field( EXPORTING it_source = lt_source
                                     val       = temp154
                           IMPORTING eo_type   = lo_type
                                     ev_table  = lv_table
                                     ev_field  = lv_field ).

            IF lr_item->alias IS NOT INITIAL.
              temp155 = lr_item->alias.
            ELSE.
              temp155 = lv_field.
            ENDIF.
            append_field( EXPORTING io_type      = lo_type
                                    ref_table    = lv_table
                                    ref_field    = temp155
                          CHANGING  ct_comp      = lt_comp
                                    ct_fieldlist = result-fieldlist ).
            INSERT lr_item->text INTO TABLE lt_part.

          ENDIF.

      ENDCASE.

    ENDLOOP.

    IF lt_comp IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `SQL_PARSER_ERROR - empty select list`.
    ENDIF.

    TRY.

        lo_line = cl_abap_structdescr=>create( lt_comp ).
        result-o_table = cl_abap_tabledescr=>create( p_line_type  = lo_line
                                                     p_table_kind = cl_abap_tabledescr=>tablekind_std
                                                     p_unique     = abap_false ).

      CATCH cx_root INTO lx_error.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = lx_error.
    ENDTRY.

    result-select_list = concat_lines_of( table = lt_part
                                          sep   = `, ` ).
    IF is_clauses-distinct = abap_true.
      result-select_list = |DISTINCT { result-select_list }|.
    ENDIF.

  ENDMETHOD.

  METHOD resolve_field.
    DATA lv_prefix TYPE string.
    DATA lv_field TYPE string.
    DATA temp156 LIKE LINE OF it_source.
    DATA lr_source LIKE REF TO temp156.
      DATA lo_struct TYPE REF TO cl_abap_structdescr.
      DATA temp157 LIKE sy-subrc.

    CLEAR eo_type.
    CLEAR ev_table.
    CLEAR ev_field.



    SPLIT to_upper( val ) AT `~` INTO lv_prefix lv_field.
    IF lv_field IS INITIAL.
      lv_field = lv_prefix.
      CLEAR lv_prefix.
    ENDIF.
    ev_field = lv_field.



    LOOP AT it_source REFERENCE INTO lr_source.
      IF lv_prefix IS NOT INITIAL AND lr_source->alias <> lv_prefix AND lr_source->name <> lv_prefix.
        CONTINUE.
      ENDIF.

      lo_struct = get_struct_by_name( lr_source->name ).

      READ TABLE lo_struct->components WITH KEY name = lv_field TRANSPORTING NO FIELDS.
      temp157 = sy-subrc.
      IF temp157 = 0.
        eo_type = lo_struct->get_component_type( lv_field ).
        ev_table = lr_source->name.
        RETURN.
      ENDIF.
    ENDLOOP.

    RAISE EXCEPTION TYPE z2ui5_cx_sql_error
      EXPORTING
        val = |SQL_PARSER_ERROR - field { val } not found in FROM clause|.

  ENDMETHOD.

  METHOD get_struct_by_name.

    DATA lo_descr TYPE REF TO cl_abap_typedescr.
        DATA temp158 TYPE REF TO cl_abap_structdescr.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = to_upper( val )
                                         RECEIVING  p_descr_ref    = lo_descr
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = |SQL_PARSER_ERROR - table { val } not found|.
    ENDIF.

    TRY.

        temp158 ?= lo_descr.
        result = temp158.
      CATCH cx_sy_move_cast_error.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = |SQL_PARSER_ERROR - { val } is not a structured data source|.
    ENDTRY.

  ENDMETHOD.

  METHOD append_field.

    DATA lv_number TYPE n LENGTH 6.
    DATA lv_ref_field LIKE ref_field.
    DATA lv_suffix TYPE i.
    DATA temp159 LIKE sy-subrc.
    DATA temp160 TYPE abap_componentdescr.
    DATA temp161 TYPE z2ui5_cl_sql_query=>ty_s_field.

    lv_number = lines( ct_comp ) + 1.


    lv_ref_field = ref_field.

    lv_suffix = 1.

    READ TABLE ct_fieldlist WITH KEY ref_field = lv_ref_field TRANSPORTING NO FIELDS.
    temp159 = sy-subrc.
    WHILE temp159 = 0.
      lv_suffix = lv_suffix + 1.
      lv_ref_field = |{ ref_field }_{ lv_suffix }|.
    ENDWHILE.


    CLEAR temp160.
    temp160-name = |F{ lv_number }|.
    temp160-type = io_type.
    INSERT temp160 INTO TABLE ct_comp.


    CLEAR temp161.
    temp161-field = |F{ lv_number }|.
    temp161-ref_table = ref_table.
    temp161-ref_field = lv_ref_field.
    INSERT temp161 INTO TABLE ct_fieldlist.

  ENDMETHOD.

  METHOD split_literals.

    DATA lv_part TYPE string.
    DATA lv_quote TYPE string.

    DATA temp162 TYPE string.
    DATA lv_val LIKE temp162.
    DATA lv_length TYPE i.
    DATA lv_pos TYPE i.
      DATA lv_char TYPE string.
    temp162 = val.

    lv_val = temp162.

    lv_length = strlen( lv_val ).

    lv_pos = 0.

    WHILE lv_pos < lv_length.


      lv_char = substring( val = lv_val
                                 off = lv_pos
                                 len = 1 ).
      lv_pos = lv_pos + 1.

      IF lv_quote IS INITIAL.
        IF lv_char = `'` OR lv_char = ````.
          INSERT lv_part INTO TABLE result.
          lv_part = lv_char.
          lv_quote = lv_char.
        ELSE.
          lv_part = lv_part && lv_char.
        ENDIF.
        CONTINUE.
      ENDIF.

      lv_part = lv_part && lv_char.
      IF lv_char <> lv_quote.
        CONTINUE.
      ENDIF.
      " a doubled delimiter is an escaped one and stays in the literal
      IF lv_pos < lv_length AND substring( val = lv_val
                                           off = lv_pos
                                           len = 1 ) = lv_quote.
        lv_part = lv_part && lv_char.
        lv_pos = lv_pos + 1.
        CONTINUE.
      ENDIF.
      INSERT lv_part INTO TABLE result.
      CLEAR lv_part.
      CLEAR lv_quote.

    ENDWHILE.

    INSERT lv_part INTO TABLE result.

  ENDMETHOD.

  METHOD upper_outside_literals.

    DATA temp163 TYPE string_table.
    DATA lv_part LIKE LINE OF temp163.
    temp163 = split_literals( val ).

    LOOP AT temp163 INTO lv_part.
      IF sy-tabix MOD 2 = 1.
        lv_part = to_upper( lv_part ).
      ENDIF.
      result = result && lv_part.
    ENDLOOP.

  ENDMETHOD.

  METHOD mask_literals.

    DATA temp164 TYPE string_table.
    DATA lv_part LIKE LINE OF temp164.
    temp164 = split_literals( val ).

    LOOP AT temp164 INTO lv_part.
      IF sy-tabix MOD 2 = 0.
        lv_part = repeat( val = `_`
                          occ = strlen( lv_part ) ).
      ENDIF.
      result = result && lv_part.
    ENDLOOP.

  ENDMETHOD.

  METHOD condense_outside_literals.

    DATA temp165 TYPE string_table.
    DATA lv_part LIKE LINE OF temp165.
    temp165 = split_literals( val ).

    LOOP AT temp165 INTO lv_part.
      IF sy-tabix MOD 2 = 1.
        WHILE lv_part CS `  `.
          REPLACE ALL OCCURRENCES OF `  ` IN lv_part WITH ` `.
        ENDWHILE.
      ENDIF.
      result = result && lv_part.
    ENDLOOP.

    result = shift_left( val = result
                         sub = ` ` ).
    result = shift_right( val = result
                          sub = ` ` ).

  ENDMETHOD.

  METHOD tokenize.

    DATA lv_token TYPE string.

    DATA temp166 TYPE string_table.
    DATA lv_part LIKE LINE OF temp166.
      DATA lv_pos TYPE i.
        DATA lv_char TYPE string.
    temp166 = split_literals( val ).

    LOOP AT temp166 INTO lv_part.

      IF sy-tabix MOD 2 = 0.
        lv_token = lv_token && lv_part.
        CONTINUE.
      ENDIF.


      lv_pos = 0.
      WHILE lv_pos < strlen( lv_part ).

        lv_char = substring( val = lv_part
                                   off = lv_pos
                                   len = 1 ).
        lv_pos = lv_pos + 1.
        IF lv_char = ` ` OR lv_char = `,`.
          IF lv_token IS NOT INITIAL.
            INSERT lv_token INTO TABLE result.
            CLEAR lv_token.
          ENDIF.
        ELSE.
          lv_token = lv_token && lv_char.
        ENDIF.
      ENDWHILE.

    ENDLOOP.

    IF lv_token IS NOT INITIAL.
      INSERT lv_token INTO TABLE result.
    ENDIF.

  ENDMETHOD.

  METHOD select_into.
        DATA lx_error TYPE REF TO cx_root.

    TRY.
        SELECT (select_list)
          FROM (is_clauses-from) INTO TABLE ct_data
          WHERE (is_clauses-where)
          GROUP BY (is_clauses-group_by)
          HAVING (is_clauses-having)
          ORDER BY (is_clauses-order_by)

          UP TO is_clauses-rows ROWS.

      CATCH cx_root INTO lx_error.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = lx_error.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
