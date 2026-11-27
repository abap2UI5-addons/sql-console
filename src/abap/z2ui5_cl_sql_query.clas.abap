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
        " joined to the segments before it with UNION ALL, which keeps
        " duplicate rows - a plain UNION removes them
        union_all   TYPE abap_bool,
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

    "! the cap run( ) applies when it is given none
    CONSTANTS c_max_rows_default TYPE i VALUE 500.

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
      BEGIN OF ty_s_order,
        name       TYPE string,
        descending TYPE abap_bool,
      END OF ty_s_order.
    TYPES ty_t_order TYPE STANDARD TABLE OF ty_s_order WITH DEFAULT KEY.

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

    "! The sort order of an ORDER BY clause over the columns of a result:
    "! every item must name a column of the select list, by field or alias
    CLASS-METHODS get_order
      IMPORTING
        order_by      TYPE clike
        it_fieldlist  TYPE ty_t_fieldlist
      RETURNING
        VALUE(result) TYPE ty_t_order
      RAISING
        z2ui5_cx_sql_error.

    "! Sorts by every column of the order in turn - a SORT BY (otab) the
    "! transpiled runtime does not know, one stable sort per column instead
    CLASS-METHODS sort_rows
      IMPORTING
        it_order TYPE ty_t_order
      CHANGING
        ct_data  TYPE STANDARD TABLE.

    "! Removes duplicate rows, as a UNION without ALL does
    CLASS-METHODS delete_duplicates
      IMPORTING
        it_fieldlist TYPE ty_t_fieldlist
      CHANGING
        ct_data      TYPE STANDARD TABLE.

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
    DATA lr_clauses TYPE REF TO ty_s_clauses.

    " an empty or negative cap is the default one, never every row
    DATA temp160 TYPE i.
    DATA lv_max_rows LIKE temp160.
    DATA lt_clauses TYPE z2ui5_cl_sql_query=>ty_t_clauses.
    DATA lv_union_rows TYPE i.
    DATA lv_union_order_by TYPE string.
    DATA lv_last TYPE i.
      DATA lv_before_last TYPE i.
      FIELD-SYMBOLS <temp161> TYPE z2ui5_cl_sql_query=>ty_s_clauses.
    DATA ls_first LIKE LINE OF lt_clauses.
    FIELD-SYMBOLS <temp3> LIKE LINE OF lt_clauses.
    DATA temp4 LIKE sy-tabix.
    DATA ls_target TYPE z2ui5_cl_sql_query=>ty_s_target.
      DATA ls_target2 TYPE z2ui5_cl_sql_query=>ty_s_target.
        DATA lv_first_cut TYPE i.
    DATA lt_source TYPE z2ui5_cl_sql_query=>ty_t_source.
    DATA temp162 TYPE z2ui5_cl_sql_query=>ty_s_result-tabname.
    DATA temp163 TYPE z2ui5_cl_sql_query=>ty_s_source.
    IF max_rows > 0.
      temp160 = max_rows.
    ELSE.
      temp160 = c_max_rows_default.
    ENDIF.

    lv_max_rows = temp160.


    lt_clauses = parse( query    = query
                              max_rows = lv_max_rows ).

    " UP TO and ORDER BY at the end of a union belong to the whole result:
    " every segment is read up to the cap, the combined rows are sorted and
    " cut afterwards. Rows beyond the cap of a segment are not read, so with
    " more rows than the cap the sorted result is a sorted part of them.

    lv_union_rows = 0.

    lv_union_order_by = ``.

    lv_last = lines( lt_clauses ).
    IF lv_last > 1.

      lv_before_last = lv_last - 1.
      LOOP AT lt_clauses REFERENCE INTO lr_clauses TO lv_before_last WHERE order_by IS NOT INITIAL.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = `SQL_PARSER_ERROR - the ORDER BY of a UNION belongs after its last SELECT`.
      ENDLOOP.

      READ TABLE lt_clauses INDEX lv_last ASSIGNING <temp161>.
IF sy-subrc <> 0.
  ASSERT 1 = 0.
ENDIF.
GET REFERENCE OF <temp161> INTO lr_clauses.
      lv_union_rows = lr_clauses->rows.
      lv_union_order_by = lr_clauses->order_by.
      lr_clauses->rows = lv_max_rows.
      CLEAR lr_clauses->order_by.
    ENDIF.




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
    " result of the segments before, converted to its line type - a UNION
    " is evaluated from left to right, so a plain one removes the duplicates
    " of everything read so far and a UNION ALL after it keeps its own
    LOOP AT lt_clauses REFERENCE INTO lr_clauses FROM 2.


      ls_target2 = build_target( lr_clauses->* ).
      CREATE DATA lr_part TYPE HANDLE ls_target-o_table.
      ASSIGN lr_part->* TO <lt_part>.

      select_into( EXPORTING is_clauses  = lr_clauses->*
                             select_list = ls_target2-select_list
                   CHANGING  ct_data     = <lt_part> ).

      APPEND LINES OF <lt_part> TO <lt_result>.

      IF lr_clauses->union_all = abap_false.
        delete_duplicates( EXPORTING it_fieldlist = ls_target-fieldlist
                           CHANGING  ct_data      = <lt_result> ).
      ENDIF.

    ENDLOOP.

    IF lv_last > 1.
      IF lv_union_order_by IS NOT INITIAL.
        sort_rows( EXPORTING it_order = get_order( order_by     = lv_union_order_by
                                                   it_fieldlist = ls_target-fieldlist )
                   CHANGING  ct_data  = <lt_result> ).
      ENDIF.
      IF lv_union_rows > 0 AND lines( <lt_result> ) > lv_union_rows.

        lv_first_cut = lv_union_rows + 1.
        DELETE <lt_result> FROM lv_first_cut.
      ENDIF.
    ENDIF.


    lt_source = get_sources( ls_first-from ).
    result-fieldlist = ls_target-fieldlist.

    CLEAR temp162.

    READ TABLE lt_source INTO temp163 INDEX 1.
    IF sy-subrc = 0.
      temp162 = temp163-name.
    ENDIF.
    result-tabname   = temp162.
    result-from      = ls_first-from.
    result-query     = normalize( query ).
    result-count     = lines( <lt_result> ).

  ENDMETHOD.

  METHOD normalize.

    DATA temp164 TYPE string.
    DATA lv_query TYPE string.
    TYPES temp1 TYPE STANDARD TABLE OF string WITH DEFAULT KEY.
DATA lt_line TYPE temp1.
    DATA temp165 LIKE LINE OF lt_line.
    DATA lr_line LIKE REF TO temp165.
    temp164 = query.

    lv_query = replace( val  = temp164
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

    DATA lv_kind TYPE string.
    DATA lv_offset TYPE i.
    DATA lv_length TYPE i.
    DATA lv_union_all TYPE abap_bool.
    DATA ls_clauses TYPE ty_s_clauses.
    DATA lv_query TYPE string.
    DATA lv_mask TYPE string.
      DATA lv_found TYPE abap_bool.
      DATA temp1 TYPE xsdboolean.
      DATA temp166 TYPE string.
      DATA temp2 TYPE xsdboolean.
    lv_query = normalize( query ).
    " keywords are searched in the masked copy, so a literal never splits the query

    lv_mask = mask_literals( lv_query ).

    DO.
      CLEAR lv_kind.
      FIND FIRST OCCURRENCE OF REGEX ` UNION (ALL |DISTINCT )?SELECT ` IN lv_mask IGNORING CASE
           MATCH OFFSET lv_offset MATCH LENGTH lv_length SUBMATCHES lv_kind.


      temp1 = boolc( sy-subrc = 0 ).
      lv_found = temp1.

      IF lv_found = abap_true.
        temp166 = substring( val = lv_query len = lv_offset ).
      ELSE.
        temp166 = lv_query.
      ENDIF.
      ls_clauses = parse_segment( val      = temp166
                                  max_rows = max_rows ).
      ls_clauses-union_all = lv_union_all.
      INSERT ls_clauses INTO TABLE result.
      IF lv_found = abap_false.
        EXIT.
      ENDIF.
      " the kind of this UNION belongs to the segment after it

      temp2 = boolc( to_upper( condense( lv_kind ) ) = `ALL` ).
      lv_union_all = temp2.
      " the next segment starts at its SELECT
      lv_offset = lv_offset + lv_length - 7.
      lv_query = lv_query+lv_offset.
      lv_mask = lv_mask+lv_offset.
    ENDDO.

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
    DATA temp167 LIKE temp5.
    DATA temp7 LIKE LINE OF temp167.
    DATA lr_keyword LIKE REF TO temp7.
      DATA lv_offset TYPE i.
        DATA temp168 TYPE ty_s_pos.
    DATA lv_from_length TYPE ty_s_pos-offset.
    FIELD-SYMBOLS <temp8> LIKE LINE OF lt_pos.
    DATA temp9 LIKE sy-tabix.
    DATA lv_from TYPE string.
    DATA temp169 LIKE LINE OF lt_pos.
    DATA lr_pos LIKE REF TO temp169.
      DATA lv_content_offset TYPE ty_s_pos-offset.
      DATA lv_index TYPE i.
      DATA temp170 LIKE sy-subrc.
      DATA temp171 LIKE sy-tabix.
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
      " checked before the conversion - a number beyond type i ended in a
      " conversion overflow instead of a message
      lv_rows = shift_left( val = lv_rows
                            sub = `0` ).
      IF strlen( lv_rows ) > 9.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = |SQL_PARSER_ERROR - UP TO { lv_rows } ROWS is too large|.
      ENDIF.
      result-rows = lv_rows.
      " UP TO 0 ROWS reads every row, and a larger number than the cap
      " overrode it - the cap of the console applies to both
      IF result-rows = 0 OR ( max_rows > 0 AND result-rows > max_rows ).
        result-rows = max_rows.
      ENDIF.
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

    temp167 = temp5.


    LOOP AT temp167
         REFERENCE INTO lr_keyword.

      FIND FIRST OCCURRENCE OF lr_keyword->* IN lv_rest_mask IGNORING CASE MATCH OFFSET lv_offset.
      IF sy-subrc = 0.

        CLEAR temp168.
        temp168-keyword = condense( lr_keyword->* ).
        temp168-offset = lv_offset.
        temp168-length = strlen( lr_keyword->* ).
        INSERT temp168 INTO TABLE lt_pos.
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


      temp171 = sy-tabix.
      READ TABLE lt_pos INDEX lv_index TRANSPORTING NO FIELDS.
      temp170 = sy-subrc.
      sy-tabix = temp171.
      IF temp170 = 0.



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
    DATA temp172 LIKE LINE OF lt_token.
    DATA lr_token LIKE REF TO temp172.
      DATA lv_last TYPE i.
      DATA temp173 TYPE string.
      DATA temp174 TYPE string.
        FIELD-SYMBOLS <temp175> LIKE LINE OF lt_item.
        DATA temp176 LIKE sy-tabix.
        FIELD-SYMBOLS <temp12> LIKE LINE OF lt_item.
        DATA temp13 LIKE sy-tabix.
      DATA temp177 LIKE LINE OF lt_item.
    lt_token = tokenize( val ).



    LOOP AT lt_token REFERENCE INTO lr_token.


      lv_last = lines( lt_item ).
      " OPTIONAL, not a plain table expression: the 7.02 downport reads a
      " table expression before the IF, the guard lv_last > 0 or not

      CLEAR temp173.

      READ TABLE lt_item INTO temp174 INDEX lv_last.
      IF sy-subrc = 0.
        temp173 = temp174.
      ENDIF.
      IF lv_last > 0
         AND (    lr_token->* = `ASCENDING`
               OR lr_token->* = `DESCENDING`
               OR ( lr_token->* = `KEY` AND temp173 = `PRIMARY` ) ).


        temp176 = sy-tabix.
        READ TABLE lt_item INDEX lv_last ASSIGNING <temp175>.
        sy-tabix = temp176.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.


        temp13 = sy-tabix.
        READ TABLE lt_item INDEX lv_last ASSIGNING <temp12>.
        sy-tabix = temp13.
        IF sy-subrc <> 0.
          ASSERT 1 = 0.
        ENDIF.
        <temp175> = |{ <temp12> } { lr_token->* }|.
        CONTINUE.
      ENDIF.


      temp177 = lr_token->*.
      INSERT temp177 INTO TABLE lt_item.

    ENDLOOP.

    result = concat_lines_of( table = lt_item
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD get_sources.

    DATA ls_source TYPE ty_s_source.
    DATA lv_state TYPE string.
    DATA lt_token TYPE string_table.
    DATA temp178 LIKE LINE OF lt_token.
    DATA lr_token LIKE REF TO temp178.
      DATA lv_token TYPE string.
      DATA lv_check_join TYPE abap_bool.
      DATA temp3 TYPE xsdboolean.
            DATA lv_last TYPE i.
            FIELD-SYMBOLS <temp179> LIKE LINE OF result.
            DATA temp180 LIKE sy-tabix.
          FIELD-SYMBOLS <temp181> LIKE LINE OF result.
          DATA temp182 LIKE sy-tabix.
    lv_state = `SOURCE`.


    lt_token = tokenize( upper_outside_literals( val ) ).



    LOOP AT lt_token REFERENCE INTO lr_token.


      lv_token = lr_token->*.


      temp3 = boolc( lv_token = `JOIN` OR lv_token = `INNER` OR lv_token = `LEFT` OR lv_token = `RIGHT` OR lv_token = `OUTER` OR lv_token = `CROSS` ).
      lv_check_join = temp3.

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


            temp180 = sy-tabix.
            READ TABLE result INDEX lv_last ASSIGNING <temp179>.
            sy-tabix = temp180.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            <temp179>-alias = lv_token.
          ENDIF.

        WHEN `ALIAS`.
          lv_last = lines( result ).


          temp182 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp181>.
          sy-tabix = temp182.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp181>-alias = lv_token.
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
          FIELD-SYMBOLS <temp183> LIKE LINE OF result.
          DATA temp184 LIKE sy-tabix.
          FIELD-SYMBOLS <temp16> LIKE LINE OF lt_token.
          DATA temp17 LIKE sy-tabix.
          FIELD-SYMBOLS <temp185> LIKE LINE OF result.
          DATA temp186 LIKE sy-tabix.
          FIELD-SYMBOLS <temp18> LIKE LINE OF result.
          DATA temp19 LIKE sy-tabix.
          FIELD-SYMBOLS <temp3> LIKE LINE OF lt_token.
          DATA temp4 LIKE sy-tabix.
          DATA lv_part LIKE LINE OF lt_token.
          FIELD-SYMBOLS <temp20> LIKE LINE OF lt_token.
          DATA temp21 LIKE sy-tabix.
        DATA lv_head TYPE string.
        DATA lv_inner TYPE string.
            FIELD-SYMBOLS <temp187> LIKE LINE OF lt_token.
            DATA temp188 LIKE sy-tabix.
            FIELD-SYMBOLS <temp189> LIKE LINE OF lt_token.
            DATA temp190 LIKE sy-tabix.
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


          temp184 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp183>.
          sy-tabix = temp184.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp17 = sy-tabix.
          READ TABLE lt_token INDEX lv_index ASSIGNING <temp16>.
          sy-tabix = temp17.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp183>-alias = <temp16>.


          temp186 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp185>.
          sy-tabix = temp186.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp19 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp18>.
          sy-tabix = temp19.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.


          temp4 = sy-tabix.
          READ TABLE lt_token INDEX lv_index ASSIGNING <temp3>.
          sy-tabix = temp4.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.
          <temp185>-text = |{ <temp18>-text } AS { <temp3> }|.
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


            temp188 = sy-tabix.
            READ TABLE lt_token INDEX lv_index ASSIGNING <temp187>.
            sy-tabix = temp188.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            ls_item-text = |{ ls_item-text } { <temp187> }|.


            temp190 = sy-tabix.
            READ TABLE lt_token INDEX lv_index ASSIGNING <temp189>.
            sy-tabix = temp190.
            IF sy-subrc <> 0.
              ASSERT 1 = 0.
            ENDIF.
            lv_inner = |{ lv_inner } { <temp189> }|.
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
    DATA temp191 TYPE z2ui5_cl_sql_query=>ty_t_item.
    DATA temp22 LIKE LINE OF temp191.
    DATA lr_item LIKE REF TO temp22.
          DATA temp192 TYPE string.
          DATA temp193 TYPE string.
          DATA lv_prefix TYPE string.
          DATA lv_name TYPE string.
          DATA lv_dummy TYPE string.
            DATA temp194 LIKE LINE OF lt_source.
            DATA lr_source LIKE REF TO temp194.
              DATA lo_struct TYPE REF TO cl_abap_structdescr.
              DATA temp195 LIKE LINE OF lo_struct->components.
              DATA lr_comp LIKE REF TO temp195.
                DATA temp196 TYPE string.
                DATA temp197 LIKE LINE OF lt_part.
            DATA temp198 TYPE string.
            DATA temp199 TYPE string.
        DATA lo_line TYPE REF TO cl_abap_structdescr.
        DATA lx_error TYPE REF TO cx_root.
    lt_source = get_sources( is_clauses-from ).
    IF lt_source IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no data source found in FROM clause`.
    ENDIF.


    temp191 = get_items( is_clauses-select_list ).


    LOOP AT temp191 REFERENCE INTO lr_item.

      CASE lr_item->kind.

        WHEN `CASE`.

          IF lr_item->alias IS NOT INITIAL.
            temp192 = lr_item->alias.
          ELSE.
            temp192 = `CASE`.
          ENDIF.
          append_field( EXPORTING io_type      = cl_abap_elemdescr=>get_string( )
                                  ref_table    = ``
                                  ref_field    = temp192
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
            temp193 = lr_item->alias.
          ELSE.
            temp193 = lv_field.
          ENDIF.
          append_field( EXPORTING io_type      = lo_type
                                  ref_table    = ``
                                  ref_field    = temp193
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

                temp196 = lr_comp->name.
                append_field( EXPORTING io_type      = lo_struct->get_component_type( lr_comp->name )
                                        ref_table    = lr_source->name
                                        ref_field    = temp196
                              CHANGING  ct_comp      = lt_comp
                                        ct_fieldlist = result-fieldlist ).

                temp197 = |{ lr_source->alias }~{ lr_comp->name }|.
                INSERT temp197 INTO TABLE lt_part.
              ENDLOOP.
            ENDLOOP.

          ELSE.


            IF lv_prefix IS NOT INITIAL.
              temp198 = |{ lv_prefix }~{ lv_name }|.
            ELSE.
              temp198 = lv_name.
            ENDIF.
            resolve_field( EXPORTING it_source = lt_source
                                     val       = temp198
                           IMPORTING eo_type   = lo_type
                                     ev_table  = lv_table
                                     ev_field  = lv_field ).

            IF lr_item->alias IS NOT INITIAL.
              temp199 = lr_item->alias.
            ELSE.
              temp199 = lv_field.
            ENDIF.
            append_field( EXPORTING io_type      = lo_type
                                    ref_table    = lv_table
                                    ref_field    = temp199
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
    DATA temp200 LIKE LINE OF it_source.
    DATA lr_source LIKE REF TO temp200.
      DATA lo_struct TYPE REF TO cl_abap_structdescr.
      DATA temp201 LIKE sy-subrc.

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
      temp201 = sy-subrc.
      IF temp201 = 0.
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
        DATA temp202 TYPE REF TO cl_abap_structdescr.

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

        temp202 ?= lo_descr.
        result = temp202.
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
    DATA temp203 LIKE sy-subrc.
    DATA temp204 TYPE abap_componentdescr.
    DATA temp205 TYPE z2ui5_cl_sql_query=>ty_s_field.

    lv_number = lines( ct_comp ) + 1.


    lv_ref_field = ref_field.

    lv_suffix = 1.

    READ TABLE ct_fieldlist WITH KEY ref_field = lv_ref_field TRANSPORTING NO FIELDS.
    temp203 = sy-subrc.
    WHILE temp203 = 0.
      lv_suffix = lv_suffix + 1.
      lv_ref_field = |{ ref_field }_{ lv_suffix }|.
    ENDWHILE.


    CLEAR temp204.
    temp204-name = |F{ lv_number }|.
    temp204-type = io_type.
    INSERT temp204 INTO TABLE ct_comp.


    CLEAR temp205.
    temp205-field = |F{ lv_number }|.
    temp205-ref_table = ref_table.
    temp205-ref_field = lv_ref_field.
    INSERT temp205 INTO TABLE ct_fieldlist.

  ENDMETHOD.

  METHOD split_literals.

    DATA lv_part TYPE string.
    DATA lv_quote TYPE string.

    DATA temp206 TYPE string.
    DATA lv_val LIKE temp206.
    DATA lv_length TYPE i.
    DATA lv_pos TYPE i.
      DATA lv_char TYPE string.
    temp206 = val.

    lv_val = temp206.

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

    DATA temp207 TYPE string_table.
    DATA lv_part LIKE LINE OF temp207.
    temp207 = split_literals( val ).

    LOOP AT temp207 INTO lv_part.
      IF sy-tabix MOD 2 = 1.
        lv_part = to_upper( lv_part ).
      ENDIF.
      result = result && lv_part.
    ENDLOOP.

  ENDMETHOD.

  METHOD mask_literals.

    DATA temp208 TYPE string_table.
    DATA lv_part LIKE LINE OF temp208.
    temp208 = split_literals( val ).

    LOOP AT temp208 INTO lv_part.
      IF sy-tabix MOD 2 = 0.
        lv_part = repeat( val = `_`
                          occ = strlen( lv_part ) ).
      ENDIF.
      result = result && lv_part.
    ENDLOOP.

  ENDMETHOD.

  METHOD condense_outside_literals.

    DATA temp209 TYPE string_table.
    DATA lv_part LIKE LINE OF temp209.
    temp209 = split_literals( val ).

    LOOP AT temp209 INTO lv_part.
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

    DATA temp210 TYPE string_table.
    DATA lv_part LIKE LINE OF temp210.
      DATA lv_pos TYPE i.
        DATA lv_char TYPE string.
    temp210 = split_literals( val ).

    LOOP AT temp210 INTO lv_part.

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

  METHOD get_order.

    DATA temp211 TYPE string_table.
    DATA lv_token LIKE LINE OF temp211.
      DATA lv_last TYPE i.
          FIELD-SYMBOLS <temp212> LIKE LINE OF result.
          DATA temp213 LIKE sy-tabix.
          DATA temp4 TYPE xsdboolean.
      DATA lv_name LIKE lv_token.
      DATA ls_field TYPE z2ui5_cl_sql_query=>ty_s_field.
      DATA temp214 TYPE z2ui5_cl_sql_query=>ty_s_order.
    temp211 = tokenize( order_by ).

    LOOP AT temp211 INTO lv_token.


      lv_last = lines( result ).
      IF lv_token = `ASCENDING` OR lv_token = `DESCENDING`.
        IF lv_last > 0.


          temp213 = sy-tabix.
          READ TABLE result INDEX lv_last ASSIGNING <temp212>.
          sy-tabix = temp213.
          IF sy-subrc <> 0.
            ASSERT 1 = 0.
          ENDIF.

          temp4 = boolc( lv_token = `DESCENDING` ).
          <temp212>-descending = temp4.
        ENDIF.
        CONTINUE.
      ENDIF.

      IF lv_token = `PRIMARY` OR lv_token = `KEY`.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = `SQL_PARSER_ERROR - ORDER BY PRIMARY KEY is not supported after a UNION, name the columns`.
      ENDIF.

      " a column is named by its field or alias, a table prefix is no part of it

      lv_name = lv_token.
      IF lv_name CS `~`.
        lv_name = substring_after( val = lv_name
                                   sub = `~` ).
      ENDIF.

      READ TABLE it_fieldlist INTO ls_field WITH KEY ref_field = lv_name.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING
            val = |SQL_PARSER_ERROR - ORDER BY { lv_token } is no column of the UNION result|.
      ENDIF.

      CLEAR temp214.
      temp214-name = ls_field-field.
      INSERT temp214 INTO TABLE result.

    ENDLOOP.

  ENDMETHOD.

  METHOD sort_rows.

    DATA lv_name TYPE string.

    " the last column first: every further sort is stable, so the earlier
    " columns decide and the later ones order what they leave equal
    DATA lv_index TYPE i.
      FIELD-SYMBOLS <temp215> LIKE LINE OF it_order.
      DATA temp216 LIKE sy-tabix.
      FIELD-SYMBOLS <temp217> LIKE LINE OF it_order.
      DATA temp218 LIKE sy-tabix.
    lv_index = lines( it_order ).
    WHILE lv_index > 0.


      temp216 = sy-tabix.
      READ TABLE it_order INDEX lv_index ASSIGNING <temp215>.
      sy-tabix = temp216.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      lv_name = <temp215>-name.


      temp218 = sy-tabix.
      READ TABLE it_order INDEX lv_index ASSIGNING <temp217>.
      sy-tabix = temp218.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      IF <temp217>-descending = abap_true.
        SORT ct_data STABLE BY (lv_name) DESCENDING.
      ELSE.
        SORT ct_data STABLE BY (lv_name) ASCENDING.
      ENDIF.
      lv_index = lv_index - 1.
    ENDWHILE.

  ENDMETHOD.

  METHOD delete_duplicates.

    DATA lt_order TYPE ty_t_order.

    " sorted by every column, equal rows are adjacent
    DATA temp219 LIKE LINE OF it_fieldlist.
    DATA lr_field LIKE REF TO temp219.
      DATA temp220 TYPE z2ui5_cl_sql_query=>ty_s_order.
    LOOP AT it_fieldlist REFERENCE INTO lr_field.

      CLEAR temp220.
      temp220-name = lr_field->field.
      INSERT temp220 INTO TABLE lt_order.
    ENDLOOP.
    sort_rows( EXPORTING it_order = lt_order
               CHANGING  ct_data  = ct_data ).
    DELETE ADJACENT DUPLICATES FROM ct_data COMPARING ALL FIELDS.

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
