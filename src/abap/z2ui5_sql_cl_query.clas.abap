CLASS z2ui5_sql_cl_query DEFINITION
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
    TYPES ty_t_fieldlist TYPE STANDARD TABLE OF ty_s_field WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_source,
        name  TYPE string,
        alias TYPE string,
      END OF ty_s_source.
    TYPES ty_t_source TYPE STANDARD TABLE OF ty_s_source WITH EMPTY KEY.

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
    TYPES ty_t_clauses TYPE STANDARD TABLE OF ty_s_clauses WITH EMPTY KEY.

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
        z2ui5_cx_util_error.

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
        z2ui5_cx_util_error.

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
    TYPES ty_t_item TYPE STANDARD TABLE OF ty_s_item WITH EMPTY KEY.

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
        z2ui5_cx_util_error.

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
        z2ui5_cx_util_error.

    CLASS-METHODS resolve_field
      IMPORTING
        it_source TYPE ty_t_source
        val       TYPE clike
      EXPORTING
        eo_type   TYPE REF TO cl_abap_datadescr
        ev_table  TYPE string
        ev_field  TYPE string
      RAISING
        z2ui5_cx_util_error.

    CLASS-METHODS get_struct_by_name
      IMPORTING
        val           TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO cl_abap_structdescr
      RAISING
        z2ui5_cx_util_error.

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

    CLASS-METHODS select_into
      IMPORTING
        is_clauses  TYPE ty_s_clauses
        select_list TYPE string
      CHANGING
        ct_data     TYPE STANDARD TABLE
      RAISING
        z2ui5_cx_util_error.

ENDCLASS.


CLASS z2ui5_sql_cl_query IMPLEMENTATION.

  METHOD run.

    FIELD-SYMBOLS <lt_result> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <lt_part>   TYPE STANDARD TABLE.
    DATA lr_part TYPE REF TO data.

    DATA(lt_clauses) = parse( query    = query
                              max_rows = max_rows ).

    DATA(ls_first) = lt_clauses[ 1 ].
    DATA(ls_target) = build_target( ls_first ).

    CREATE DATA result-data TYPE HANDLE ls_target-o_table.
    ASSIGN result-data->* TO <lt_result>.

    select_into( EXPORTING is_clauses  = ls_first
                           select_list = ls_target-select_list
                 CHANGING  ct_data     = <lt_result> ).

    " union segments are executed separately and appended to the
    " result of the first segment, converted to its line type
    LOOP AT lt_clauses REFERENCE INTO DATA(lr_clauses) FROM 2.

      DATA(ls_target2) = build_target( lr_clauses->* ).
      CREATE DATA lr_part TYPE HANDLE ls_target-o_table.
      ASSIGN lr_part->* TO <lt_part>.

      select_into( EXPORTING is_clauses  = lr_clauses->*
                             select_list = ls_target2-select_list
                   CHANGING  ct_data     = <lt_part> ).

      APPEND LINES OF <lt_part> TO <lt_result>.

    ENDLOOP.

    DATA(lt_source) = get_sources( ls_first-from ).
    result-fieldlist = ls_target-fieldlist.
    result-tabname   = VALUE #( lt_source[ 1 ]-name OPTIONAL ).
    result-from      = ls_first-from.
    result-query     = normalize( query ).
    result-count     = lines( <lt_result> ).

  ENDMETHOD.

  METHOD normalize.

    DATA(lv_query) = replace( val  = CONV string( query )
                              sub  = cl_abap_char_utilities=>cr_lf
                              with = cl_abap_char_utilities=>newline
                              occ  = 0 ).

    SPLIT lv_query AT cl_abap_char_utilities=>newline INTO TABLE DATA(lt_line).
    LOOP AT lt_line REFERENCE INTO DATA(lr_line).
      lr_line->* = condense( lr_line->* ).
    ENDLOOP.
    DELETE lt_line WHERE table_line IS INITIAL.

    result = concat_lines_of( table = lt_line
                              sep   = ` ` ).

  ENDMETHOD.

  METHOD parse.

    DATA lt_segment TYPE string_table.
    DATA(lv_query) = normalize( query ).

    DO.
      FIND FIRST OCCURRENCE OF ` UNION SELECT ` IN lv_query IGNORING CASE MATCH OFFSET DATA(lv_offset).
      IF sy-subrc <> 0.
        INSERT lv_query INTO TABLE lt_segment.
        EXIT.
      ENDIF.
      INSERT lv_query(lv_offset) INTO TABLE lt_segment.
      lv_offset = lv_offset + 7.
      lv_query = lv_query+lv_offset.
    ENDDO.

    LOOP AT lt_segment REFERENCE INTO DATA(lr_segment).
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
    DATA lt_pos TYPE STANDARD TABLE OF ty_s_pos WITH EMPTY KEY.
    DATA lv_rows TYPE string.

    DATA(lv_segment) = val.

    FIND FIRST OCCURRENCE OF REGEX `UP TO ([0-9]+) ROWS` IN lv_segment IGNORING CASE SUBMATCHES lv_rows.
    IF sy-subrc = 0.
      result-rows = lv_rows.
      REPLACE FIRST OCCURRENCE OF REGEX `UP TO ([0-9]+) ROWS` IN lv_segment WITH `` IGNORING CASE.
    ELSE.
      result-rows = max_rows.
    ENDIF.

    REPLACE FIRST OCCURRENCE OF REGEX `(INTO|APPENDING)( TABLE| CORRESPONDING FIELDS OF TABLE| CORRESPONDING FIELDS OF)? @?\S+`
            IN lv_segment WITH `` IGNORING CASE.

    FIND FIRST OCCURRENCE OF `SELECT ` IN lv_segment IGNORING CASE MATCH OFFSET DATA(lv_select_offset).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_util_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no SELECT found in query`.
    ENDIF.

    FIND FIRST OCCURRENCE OF ` FROM ` IN SECTION OFFSET lv_select_offset OF lv_segment
         IGNORING CASE MATCH OFFSET DATA(lv_from_offset).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_util_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no FROM found in query`.
    ENDIF.

    DATA(lv_select_start) = lv_select_offset + 7.
    DATA(lv_length) = lv_from_offset - lv_select_start.
    IF lv_length <= 0.
      RAISE EXCEPTION TYPE z2ui5_cx_util_error
        EXPORTING
          val = `SQL_PARSER_ERROR - empty select list`.
    ENDIF.

    DATA(lv_select) = condense( to_upper( lv_segment+lv_select_start(lv_length) ) ).
    IF strlen( lv_select ) > 7 AND lv_select(7) = `SINGLE `.
      result-rows = 1.
      lv_select = condense( lv_select+7 ).
    ENDIF.
    IF strlen( lv_select ) > 9 AND lv_select(9) = `DISTINCT `.
      result-distinct = abap_true.
      lv_select = condense( lv_select+9 ).
    ENDIF.
    result-select_list = lv_select.

    DATA(lv_rest_offset) = lv_from_offset + 6.
    DATA(lv_rest) = lv_segment+lv_rest_offset.

    LOOP AT VALUE string_table( ( ` WHERE ` ) ( ` GROUP BY ` ) ( ` HAVING ` ) ( ` ORDER BY ` ) )
         REFERENCE INTO DATA(lr_keyword).
      FIND FIRST OCCURRENCE OF lr_keyword->* IN lv_rest IGNORING CASE MATCH OFFSET DATA(lv_offset).
      IF sy-subrc = 0.
        INSERT VALUE #( keyword = condense( lr_keyword->* )
                        offset  = lv_offset
                        length  = strlen( lr_keyword->* ) ) INTO TABLE lt_pos.
      ENDIF.
    ENDLOOP.
    SORT lt_pos BY offset.

    IF lt_pos IS INITIAL.
      result-from = condense( to_upper( lv_rest ) ).
      RETURN.
    ENDIF.

    DATA(lv_from_length) = lt_pos[ 1 ]-offset.
    result-from = condense( to_upper( lv_rest(lv_from_length) ) ).

    LOOP AT lt_pos REFERENCE INTO DATA(lr_pos).
      DATA(lv_content_offset) = lr_pos->offset + lr_pos->length.
      DATA(lv_index) = sy-tabix + 1.
      IF line_exists( lt_pos[ lv_index ] ).
        DATA(lv_content_length) = lt_pos[ lv_index ]-offset - lv_content_offset.
        DATA(lv_content) = lv_rest+lv_content_offset(lv_content_length).
      ELSE.
        lv_content = lv_rest+lv_content_offset.
      ENDIF.
      lv_content = condense( lv_content ).

      CASE lr_pos->keyword.
        WHEN `WHERE`.
          result-where = lv_content.
        WHEN `GROUP BY`.
          result-group_by = join_by_comma( to_upper( lv_content ) ).
        WHEN `HAVING`.
          result-having = lv_content.
        WHEN `ORDER BY`.
          result-order_by = join_order_by( to_upper( lv_content ) ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD join_by_comma.

    DATA(lv_val) = CONV string( val ).
    REPLACE ALL OCCURRENCES OF `,` IN lv_val WITH ` `.
    SPLIT condense( lv_val ) AT ` ` INTO TABLE DATA(lt_token).
    result = concat_lines_of( table = lt_token
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD join_order_by.

    DATA lt_item TYPE string_table.

    DATA(lv_val) = CONV string( val ).
    REPLACE ALL OCCURRENCES OF `,` IN lv_val WITH ` `.
    SPLIT condense( lv_val ) AT ` ` INTO TABLE DATA(lt_token).

    LOOP AT lt_token REFERENCE INTO DATA(lr_token).

      DATA(lv_last) = lines( lt_item ).
      IF lv_last > 0
         AND (    lr_token->* = `ASCENDING`
               OR lr_token->* = `DESCENDING`
               OR ( lr_token->* = `KEY` AND lt_item[ lv_last ] = `PRIMARY` ) ).
        lt_item[ lv_last ] = |{ lt_item[ lv_last ] } { lr_token->* }|.
        CONTINUE.
      ENDIF.

      INSERT CONV string( lr_token->* ) INTO TABLE lt_item.

    ENDLOOP.

    result = concat_lines_of( table = lt_item
                              sep   = `, ` ).

  ENDMETHOD.

  METHOD get_sources.

    DATA ls_source TYPE ty_s_source.
    DATA(lv_state) = `SOURCE`.

    DATA(lv_from) = condense( to_upper( val ) ).
    REPLACE ALL OCCURRENCES OF `,` IN lv_from WITH ` `.
    SPLIT condense( lv_from ) AT ` ` INTO TABLE DATA(lt_token).

    LOOP AT lt_token REFERENCE INTO DATA(lr_token).

      DATA(lv_token) = lr_token->*.
      DATA(lv_check_join) = xsdbool( lv_token = `JOIN` OR lv_token = `INNER` OR lv_token = `LEFT`
                                     OR lv_token = `RIGHT` OR lv_token = `OUTER` OR lv_token = `CROSS` ).

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
            DATA(lv_last) = lines( result ).
            result[ lv_last ]-alias = lv_token.
          ENDIF.

        WHEN `ALIAS`.
          lv_last = lines( result ).
          result[ lv_last ]-alias = lv_token.
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

    DATA(lv_list) = CONV string( val ).
    REPLACE ALL OCCURRENCES OF `,` IN lv_list WITH ` `.
    SPLIT condense( lv_list ) AT ` ` INTO TABLE DATA(lt_token).

    DATA(lv_index) = 0.
    WHILE lv_index < lines( lt_token ).

      lv_index = lv_index + 1.
      DATA(lv_token) = lt_token[ lv_index ].

      IF lv_token = `AS`.
        lv_index = lv_index + 1.
        DATA(lv_last) = lines( result ).
        IF lv_index <= lines( lt_token ) AND lv_last > 0.
          result[ lv_last ]-alias = lt_token[ lv_index ].
          result[ lv_last ]-text = |{ result[ lv_last ]-text } AS { lt_token[ lv_index ] }|.
        ENDIF.
        CONTINUE.
      ENDIF.

      CLEAR ls_item.

      IF lv_token = `CASE`.
        ls_item-kind = `CASE`.
        ls_item-text = lv_token.
        WHILE lv_index < lines( lt_token ).
          lv_index = lv_index + 1.
          DATA(lv_part) = lt_token[ lv_index ].
          ls_item-text = |{ ls_item-text } { lv_part }|.
          IF lv_part = `END`.
            EXIT.
          ENDIF.
        ENDWHILE.
        INSERT ls_item INTO TABLE result.
        CONTINUE.
      ENDIF.

      IF lv_token CS `(`.
        SPLIT lv_token AT `(` INTO DATA(lv_head) DATA(lv_inner).
        IF lv_head = `COUNT` OR lv_head = `AVG` OR lv_head = `SUM` OR lv_head = `MIN` OR lv_head = `MAX`.
          ls_item-kind = `AGG`.
          ls_item-agg = lv_head.
          ls_item-text = lv_token.
          WHILE ls_item-text NS `)` AND lv_index < lines( lt_token ).
            lv_index = lv_index + 1.
            ls_item-text = |{ ls_item-text } { lt_token[ lv_index ] }|.
            lv_inner = |{ lv_inner } { lt_token[ lv_index ] }|.
          ENDWHILE.
          SPLIT lv_inner AT `)` INTO lv_inner DATA(lv_dummy).
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

    DATA(lt_source) = get_sources( is_clauses-from ).
    IF lt_source IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_util_error
        EXPORTING
          val = `SQL_PARSER_ERROR - no data source found in FROM clause`.
    ENDIF.

    LOOP AT get_items( is_clauses-select_list ) REFERENCE INTO DATA(lr_item).

      CASE lr_item->kind.

        WHEN `CASE`.
          append_field( EXPORTING io_type      = cl_abap_elemdescr=>get_string( )
                                  ref_table    = ``
                                  ref_field    = COND #( WHEN lr_item->alias IS NOT INITIAL
                                                         THEN lr_item->alias
                                                         ELSE `CASE` )
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
              lv_field = lr_item->inner.
            WHEN OTHERS.
              resolve_field( EXPORTING it_source = lt_source
                                       val       = lr_item->inner
                             IMPORTING eo_type   = lo_type
                                       ev_field  = lv_field ).
          ENDCASE.
          append_field( EXPORTING io_type      = lo_type
                                  ref_table    = ``
                                  ref_field    = COND #( WHEN lr_item->alias IS NOT INITIAL
                                                         THEN lr_item->alias
                                                         ELSE lv_field )
                        CHANGING  ct_comp      = lt_comp
                                  ct_fieldlist = result-fieldlist ).
          INSERT lr_item->text INTO TABLE lt_part.

        WHEN `FIELD`.

          SPLIT lr_item->text AT `~` INTO DATA(lv_prefix) DATA(lv_name).
          IF lv_name IS INITIAL.
            lv_name = lv_prefix.
            CLEAR lv_prefix.
          ENDIF.
          " strip a trailing ` AS alias` from the field part (qualified or not)
          SPLIT lv_name AT ` ` INTO lv_name DATA(lv_dummy).

          IF lv_name = `*`.

            LOOP AT lt_source REFERENCE INTO DATA(lr_source).
              IF lv_prefix IS NOT INITIAL AND lr_source->alias <> lv_prefix AND lr_source->name <> lv_prefix.
                CONTINUE.
              ENDIF.
              DATA(lo_struct) = get_struct_by_name( lr_source->name ).
              LOOP AT lo_struct->components REFERENCE INTO DATA(lr_comp).
                append_field( EXPORTING io_type      = lo_struct->get_component_type( lr_comp->name )
                                        ref_table    = lr_source->name
                                        ref_field    = CONV #( lr_comp->name )
                              CHANGING  ct_comp      = lt_comp
                                        ct_fieldlist = result-fieldlist ).
                INSERT |{ lr_source->alias }~{ lr_comp->name }| INTO TABLE lt_part.
              ENDLOOP.
            ENDLOOP.

          ELSE.

            resolve_field( EXPORTING it_source = lt_source
                                     val       = COND #( WHEN lv_prefix IS NOT INITIAL
                                                         THEN |{ lv_prefix }~{ lv_name }|
                                                         ELSE lv_name )
                           IMPORTING eo_type   = lo_type
                                     ev_table  = lv_table
                                     ev_field  = lv_field ).
            append_field( EXPORTING io_type      = lo_type
                                    ref_table    = lv_table
                                    ref_field    = COND #( WHEN lr_item->alias IS NOT INITIAL
                                                           THEN lr_item->alias
                                                           ELSE lv_field )
                          CHANGING  ct_comp      = lt_comp
                                    ct_fieldlist = result-fieldlist ).
            INSERT lr_item->text INTO TABLE lt_part.

          ENDIF.

      ENDCASE.

    ENDLOOP.

    IF lt_comp IS INITIAL.
      RAISE EXCEPTION TYPE z2ui5_cx_util_error
        EXPORTING
          val = `SQL_PARSER_ERROR - empty select list`.
    ENDIF.

    TRY.
        DATA(lo_line) = cl_abap_structdescr=>create( lt_comp ).
        result-o_table = cl_abap_tabledescr=>create( p_line_type  = lo_line
                                                     p_table_kind = cl_abap_tabledescr=>tablekind_std
                                                     p_unique     = abap_false ).
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE z2ui5_cx_util_error
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

    CLEAR eo_type.
    CLEAR ev_table.
    CLEAR ev_field.

    SPLIT to_upper( val ) AT `~` INTO DATA(lv_prefix) DATA(lv_field).
    IF lv_field IS INITIAL.
      lv_field = lv_prefix.
      CLEAR lv_prefix.
    ENDIF.
    ev_field = lv_field.

    LOOP AT it_source REFERENCE INTO DATA(lr_source).
      IF lv_prefix IS NOT INITIAL AND lr_source->alias <> lv_prefix AND lr_source->name <> lv_prefix.
        CONTINUE.
      ENDIF.
      DATA(lo_struct) = get_struct_by_name( lr_source->name ).
      IF line_exists( lo_struct->components[ name = lv_field ] ).
        eo_type = lo_struct->get_component_type( lv_field ).
        ev_table = lr_source->name.
        RETURN.
      ENDIF.
    ENDLOOP.

    RAISE EXCEPTION TYPE z2ui5_cx_util_error
      EXPORTING
        val = |SQL_PARSER_ERROR - field { val } not found in FROM clause|.

  ENDMETHOD.

  METHOD get_struct_by_name.

    DATA lo_descr TYPE REF TO cl_abap_typedescr.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = to_upper( val )
                                         RECEIVING  p_descr_ref    = lo_descr
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_util_error
        EXPORTING
          val = |SQL_PARSER_ERROR - table { val } not found|.
    ENDIF.

    TRY.
        result = CAST cl_abap_structdescr( lo_descr ).
      CATCH cx_sy_move_cast_error.
        RAISE EXCEPTION TYPE z2ui5_cx_util_error
          EXPORTING
            val = |SQL_PARSER_ERROR - { val } is not a structured data source|.
    ENDTRY.

  ENDMETHOD.

  METHOD append_field.

    DATA lv_number TYPE n LENGTH 6.

    lv_number = lines( ct_comp ) + 1.

    DATA(lv_ref_field) = ref_field.
    DATA(lv_suffix) = 1.
    WHILE line_exists( ct_fieldlist[ ref_field = lv_ref_field ] ).
      lv_suffix = lv_suffix + 1.
      lv_ref_field = |{ ref_field }_{ lv_suffix }|.
    ENDWHILE.

    INSERT VALUE #( name = |F{ lv_number }|
                    type = io_type ) INTO TABLE ct_comp.

    INSERT VALUE #( field     = |F{ lv_number }|
                    ref_table = ref_table
                    ref_field = lv_ref_field ) INTO TABLE ct_fieldlist.

  ENDMETHOD.

  METHOD select_into.

    TRY.
        SELECT (select_list)
          FROM (is_clauses-from)
          WHERE (is_clauses-where)
          GROUP BY (is_clauses-group_by)
          HAVING (is_clauses-having)
          ORDER BY (is_clauses-order_by)
          INTO TABLE @ct_data
          UP TO @is_clauses-rows ROWS.
      CATCH cx_root INTO DATA(lx_error).
        RAISE EXCEPTION TYPE z2ui5_cx_util_error
          EXPORTING
            val = lx_error.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
