CLASS z2ui5_cl_sql_db DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS delete_by_handle
      IMPORTING
        uname        TYPE clike OPTIONAL
        handle       TYPE clike OPTIONAL
        handle2      TYPE clike OPTIONAL
        handle3      TYPE clike OPTIONAL
        check_commit TYPE abap_bool DEFAULT abap_true.

    CLASS-METHODS save
      IMPORTING
        uname         TYPE clike OPTIONAL
        handle        TYPE clike OPTIONAL
        handle2       TYPE clike OPTIONAL
        handle3       TYPE clike OPTIONAL
        data          TYPE any
        check_commit  TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(result) TYPE string.

    CLASS-METHODS load_by_id
      IMPORTING
        id            TYPE clike OPTIONAL
      EXPORTING
        VALUE(result) TYPE any.

    CLASS-METHODS load_by_handle
      IMPORTING
        uname         TYPE clike OPTIONAL
        handle        TYPE clike OPTIONAL
        handle2       TYPE clike OPTIONAL
        handle3       TYPE clike OPTIONAL
      EXPORTING
        VALUE(result) TYPE any.

    TYPES ty_s_db TYPE z2ui5_t_33.
    TYPES ty_t_db TYPE STANDARD TABLE OF ty_s_db WITH EMPTY KEY.

    " only supplied parameters filter the selection, initial values of
    " unsupplied parameters do not restrict the result
    CLASS-METHODS load_multi_by_handle
      IMPORTING
        uname         TYPE clike OPTIONAL
        handle        TYPE clike OPTIONAL
        handle2       TYPE clike OPTIONAL
        handle3       TYPE clike OPTIONAL
      RETURNING
        VALUE(result) TYPE ty_t_db.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS get_id_by_handle
      IMPORTING
        is_db         TYPE ty_s_db
      RETURNING
        VALUE(result) TYPE string.
ENDCLASS.



CLASS z2ui5_cl_sql_db IMPLEMENTATION.



  METHOD delete_by_handle.

    DELETE FROM z2ui5_t_33
        WHERE
           uname = @uname
            AND handle = @handle
            AND handle2 = @handle2
            AND handle3 = @handle3.

    IF check_commit = abap_true.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.


  METHOD load_by_handle.

    SELECT SINGLE data
      FROM z2ui5_t_33
       WHERE
        uname = @uname
        AND handle = @handle
        AND handle2 = @handle2
        AND handle3 = @handle3 "#EC WARNOK
      INTO @DATA(lv_data).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `NO_ENTRY_FOR_HANDLE_EXISTS`.
    ENDIF.

    z2ui5_cl_sql_context=>xml_parse(
      EXPORTING
        xml = lv_data
      IMPORTING
        any = result ).

  ENDMETHOD.


  METHOD load_multi_by_handle.

    DATA lr_uname   TYPE RANGE OF z2ui5_t_33-uname.
    DATA lr_handle  TYPE RANGE OF z2ui5_t_33-handle.
    DATA lr_handle2 TYPE RANGE OF z2ui5_t_33-handle2.
    DATA lr_handle3 TYPE RANGE OF z2ui5_t_33-handle3.

    IF uname IS SUPPLIED.
      lr_uname = VALUE #( ( sign = `I` option = `EQ` low = uname ) ).
    ENDIF.
    IF handle IS SUPPLIED.
      lr_handle = VALUE #( ( sign = `I` option = `EQ` low = handle ) ).
    ENDIF.
    IF handle2 IS SUPPLIED.
      lr_handle2 = VALUE #( ( sign = `I` option = `EQ` low = handle2 ) ).
    ENDIF.
    IF handle3 IS SUPPLIED.
      lr_handle3 = VALUE #( ( sign = `I` option = `EQ` low = handle3 ) ).
    ENDIF.

    SELECT FROM z2ui5_t_33
      FIELDS *
      WHERE uname   IN @lr_uname
        AND handle  IN @lr_handle
        AND handle2 IN @lr_handle2
        AND handle3 IN @lr_handle3 "#EC WARNOK
      INTO CORRESPONDING FIELDS OF TABLE @result.

  ENDMETHOD.


  METHOD load_by_id.

    SELECT SINGLE data
      FROM z2ui5_t_33
      WHERE id = @id  "#EC WARNOK
      INTO @DATA(lv_data).
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = |NO_ENTRY_FOR_ID_EXISTS: { id }|.
    ENDIF.

    z2ui5_cl_sql_context=>xml_parse(
      EXPORTING
        xml = lv_data
      IMPORTING
        any = result ).

  ENDMETHOD.


  METHOD save.

    SELECT SINGLE id
      FROM z2ui5_t_33
       WHERE
        uname = @uname
        AND handle = @handle
        AND handle2 = @handle2 "#EC WARNOK
        AND handle3 = @handle3
      INTO @DATA(lv_id) ##SUBRC_OK.

    DATA(ls_db) = VALUE z2ui5_t_33(
        uname   = uname
        handle  = handle
        handle2 = handle2
        handle3 = handle3 ).
    " the declared static exception of xml_stringify (data it cannot
    " serialize) left save( ) as CX_SY_NO_HANDLER
    TRY.
        ls_db-data = z2ui5_cl_sql_context=>xml_stringify( data ).
      CATCH cx_transformation_error INTO DATA(x).
        RAISE EXCEPTION TYPE z2ui5_cx_sql_error
          EXPORTING val      = `DB_SAVE_FAILED - the data cannot be serialized`
                    previous = x.
    ENDTRY.

    " The table's key is the id alone, and nothing locks the handles: two
    " saves of the same handles running in parallel both found no row,
    " each inserted one under a random id, and from then on save and
    " load_by_handle picked either row - a lost update that looked like
    " random data. An id derived from the handles makes the second MODIFY
    " an update of the first. A row that already exists keeps its id
    IF lv_id IS NOT INITIAL.
      ls_db-id = lv_id.
    ELSE.
      ls_db-id = get_id_by_handle( ls_db ).
    ENDIF.

    MODIFY z2ui5_t_33 FROM @ls_db.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE z2ui5_cx_sql_error
        EXPORTING
          val = `DB_SAVE_FAILED`.
    ENDIF.

    IF check_commit = abap_true.
      COMMIT WORK AND WAIT.
    ENDIF.

    result = ls_db-id.

  ENDMETHOD.

  METHOD get_id_by_handle.

    " each handle with its length in front, so that no two tuples give the
    " same text; SHA-256 in hex, its first 32 characters fill the id
    DATA(lv_key) = |{ strlen( is_db-uname ) }:{ is_db-uname }|
                && |{ strlen( is_db-handle ) }:{ is_db-handle }|
                && |{ strlen( is_db-handle2 ) }:{ is_db-handle2 }|
                && |{ strlen( is_db-handle3 ) }:{ is_db-handle3 }|.
    DATA(lv_hash) = to_upper( z2ui5_cl_sql_context=>hash_string( lv_key ) ).

    " no digest class answers: hash_string gives the text back - a random
    " id then, as before
    IF strlen( lv_hash ) = 64 AND lv_hash CO `0123456789ABCDEF`.
      result = lv_hash(32).
    ELSE.
      result = z2ui5_cl_sql_context=>uuid_get_c32( ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
