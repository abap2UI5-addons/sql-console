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

    CLASS-METHODS load_by_handle
      IMPORTING
        uname         TYPE clike OPTIONAL
        handle        TYPE clike OPTIONAL
        handle2       TYPE clike OPTIONAL
        handle3       TYPE clike OPTIONAL
      EXPORTING
        VALUE(result) TYPE any.

    TYPES ty_s_db TYPE z2ui5_t_33.
    TYPES ty_t_db TYPE STANDARD TABLE OF ty_s_db WITH DEFAULT KEY.

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
           uname = uname
            AND handle = handle
            AND handle2 = handle2
            AND handle3 = handle3.

    IF check_commit = abap_true.
      COMMIT WORK AND WAIT.
    ENDIF.

  ENDMETHOD.


  METHOD load_by_handle.

    DATA lv_data TYPE z2ui5_t_33-data.
    SELECT SINGLE data
      FROM z2ui5_t_33 INTO lv_data
       WHERE
        uname = uname
        AND handle = handle
        AND handle2 = handle2
        AND handle3 = handle3 "#EC WARNOK
      .
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
      DATA temp1 LIKE lr_uname.
      DATA temp2 LIKE LINE OF temp1.
      DATA temp3 LIKE lr_handle.
      DATA temp4 LIKE LINE OF temp3.
      DATA temp5 LIKE lr_handle2.
      DATA temp6 LIKE LINE OF temp5.
      DATA temp7 LIKE lr_handle3.
      DATA temp8 LIKE LINE OF temp7.

    IF uname IS SUPPLIED.

      CLEAR temp1.

      temp2-sign = `I`.
      temp2-option = `EQ`.
      temp2-low = uname.
      INSERT temp2 INTO TABLE temp1.
      lr_uname = temp1.
    ENDIF.
    IF handle IS SUPPLIED.

      CLEAR temp3.

      temp4-sign = `I`.
      temp4-option = `EQ`.
      temp4-low = handle.
      INSERT temp4 INTO TABLE temp3.
      lr_handle = temp3.
    ENDIF.
    IF handle2 IS SUPPLIED.

      CLEAR temp5.

      temp6-sign = `I`.
      temp6-option = `EQ`.
      temp6-low = handle2.
      INSERT temp6 INTO TABLE temp5.
      lr_handle2 = temp5.
    ENDIF.
    IF handle3 IS SUPPLIED.

      CLEAR temp7.

      temp8-sign = `I`.
      temp8-option = `EQ`.
      temp8-low = handle3.
      INSERT temp8 INTO TABLE temp7.
      lr_handle3 = temp7.
    ENDIF.

    SELECT * FROM z2ui5_t_33 INTO CORRESPONDING FIELDS OF TABLE result

      WHERE uname   IN lr_uname
        AND handle  IN lr_handle
        AND handle2 IN lr_handle2
        AND handle3 IN lr_handle3 "#EC WARNOK
      .

  ENDMETHOD.


  METHOD save.

    DATA lv_id TYPE z2ui5_t_33-id.
    DATA temp9 TYPE z2ui5_t_33.
    DATA ls_db LIKE temp9.
        DATA x TYPE REF TO cx_transformation_error.
    SELECT SINGLE id
      FROM z2ui5_t_33 INTO lv_id
       WHERE
        uname = uname
        AND handle = handle
        AND handle2 = handle2 "#EC WARNOK
        AND handle3 = handle3
       ##SUBRC_OK.


    CLEAR temp9.
    temp9-uname = uname.
    temp9-handle = handle.
    temp9-handle2 = handle2.
    temp9-handle3 = handle3.

    ls_db = temp9.
    " the declared static exception of xml_stringify (data it cannot
    " serialize) left save( ) as CX_SY_NO_HANDLER
    TRY.
        ls_db-data = z2ui5_cl_sql_context=>xml_stringify( data ).

      CATCH cx_transformation_error INTO x.
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

    MODIFY z2ui5_t_33 FROM ls_db.
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
    DATA lv_key TYPE string.
    DATA lv_hash TYPE string.
    lv_key = |{ strlen( is_db-uname ) }:{ is_db-uname }|
                && |{ strlen( is_db-handle ) }:{ is_db-handle }|
                && |{ strlen( is_db-handle2 ) }:{ is_db-handle2 }|
                && |{ strlen( is_db-handle3 ) }:{ is_db-handle3 }|.

    lv_hash = to_upper( z2ui5_cl_sql_context=>hash_string( lv_key ) ).

    " no digest class answers: hash_string gives the text back - a random
    " id then, as before
    IF strlen( lv_hash ) = 64 AND lv_hash CO `0123456789ABCDEF`.
      result = lv_hash(32).
    ELSE.
      result = z2ui5_cl_sql_context=>uuid_get_c32( ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
