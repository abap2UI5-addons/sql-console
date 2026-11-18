CLASS z2ui5_cl_sql_history_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS c_handle_history TYPE string VALUE `Z2UI5_SQL_CONSOLE_HISTORY` ##NO_TEXT.
    CONSTANTS c_handle_draft   TYPE string VALUE `Z2UI5_SQL_CONSOLE_DRAFT` ##NO_TEXT.

    TYPES:
      BEGIN OF ty_s_entry,
        uuid        TYPE c LENGTH 32,
        timestampl  TYPE timestampl,
        uname       TYPE c LENGTH 20,
        tabname     TYPE c LENGTH 20,
        counter     TYPE c LENGTH 20,
        sql_command TYPE string,
        result_data TYPE string,
      END OF ty_s_entry.
    TYPES ty_t_entry TYPE STANDARD TABLE OF ty_s_entry WITH DEFAULT KEY.

    CLASS-METHODS db_create
      IMPORTING
        VALUE(val) TYPE ty_s_entry.

    CLASS-METHODS db_read_multi_by_user
      IMPORTING
        val           TYPE clike DEFAULT sy-uname
      RETURNING
        VALUE(result) TYPE ty_t_entry.

    CLASS-METHODS db_read_by_id
      IMPORTING
        val           TYPE clike DEFAULT sy-uname
      RETURNING
        VALUE(result) TYPE ty_s_entry.

    CLASS-METHODS db_delete
      IMPORTING
        user TYPE clike DEFAULT sy-uname.

    CLASS-METHODS db_create_draft
      IMPORTING
        VALUE(val) TYPE clike.

    CLASS-METHODS db_read_draft
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS z2ui5_cl_sql_history_api IMPLEMENTATION.

  METHOD db_create.

    val-uname = sy-uname.
    z2ui5_cl_sql_db=>save( uname   = val-uname
                            handle  = c_handle_history
                            handle2 = val-uuid
                            data    = val ).

  ENDMETHOD.

  METHOD db_read_multi_by_user.

    DATA ls_entry TYPE ty_s_entry.

    DATA temp1 TYPE z2ui5_cl_sql_db=>ty_t_db.
    DATA temp2 LIKE LINE OF temp1.
    DATA lr_db LIKE REF TO temp2.
    temp1 = z2ui5_cl_sql_db=>load_multi_by_handle( uname = val handle = c_handle_history ).


    LOOP AT temp1 REFERENCE INTO lr_db.

      z2ui5_cl_sql_context=>xml_parse( EXPORTING xml = lr_db->data
                                IMPORTING any = ls_entry ).
      INSERT ls_entry INTO TABLE result.

    ENDLOOP.

  ENDMETHOD.

  METHOD db_delete.

    DATA temp2 TYPE z2ui5_cl_sql_db=>ty_t_db.
    DATA temp3 LIKE LINE OF temp2.
    DATA lr_db LIKE REF TO temp3.
    temp2 = z2ui5_cl_sql_db=>load_multi_by_handle( uname = user handle = c_handle_history ).


    LOOP AT temp2 REFERENCE INTO lr_db.

      z2ui5_cl_sql_db=>delete_by_handle( uname        = lr_db->uname
                                          handle       = lr_db->handle
                                          handle2      = lr_db->handle2
                                          check_commit = abap_false ).

    ENDLOOP.
    COMMIT WORK AND WAIT.

  ENDMETHOD.

  METHOD db_create_draft.

    DATA temp3 TYPE string.
    temp3 = val.
    z2ui5_cl_sql_db=>save( uname  = sy-uname
                            handle = c_handle_draft
                            data   = temp3 ).

  ENDMETHOD.

  METHOD db_read_draft.

    TRY.
        z2ui5_cl_sql_db=>load_by_handle( EXPORTING uname  = sy-uname
                                                    handle = c_handle_draft
                                          IMPORTING result = result ).
      CATCH z2ui5_cx_sql_error.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD db_read_by_id.

    " the id comes from the history list, which is bound to the view - only
    " an entry of the user's own history is read, as db_read_multi_by_user
    DATA lt_db TYPE z2ui5_cl_sql_db=>ty_t_db.
    FIELD-SYMBOLS <temp4> LIKE LINE OF lt_db.
    DATA temp5 LIKE sy-tabix.
    lt_db = z2ui5_cl_sql_db=>load_multi_by_handle( uname   = sy-uname
                                                          handle  = c_handle_history
                                                          handle2 = val ).
    IF lt_db IS INITIAL.
      RETURN.
    ENDIF.



    temp5 = sy-tabix.
    READ TABLE lt_db INDEX 1 ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    z2ui5_cl_sql_context=>xml_parse( EXPORTING xml = <temp4>-data
                              IMPORTING any = result ).

  ENDMETHOD.

ENDCLASS.
