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
    TYPES ty_t_entry TYPE STANDARD TABLE OF ty_s_entry WITH EMPTY KEY.

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

    "! Deprecated - the console no longer keeps a draft; this method has no
    "! caller left and will be removed in a later release
    CLASS-METHODS db_create_draft
      IMPORTING
        VALUE(val) TYPE clike.

    "! Deprecated - the console no longer keeps a draft; this method has no
    "! caller left and will be removed in a later release
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

    LOOP AT z2ui5_cl_sql_db=>load_multi_by_handle( uname  = val
                                                    handle = c_handle_history ) REFERENCE INTO DATA(lr_db).

      " only the requested user's own history rows are read
      IF lr_db->uname <> val OR lr_db->handle <> c_handle_history.
        CONTINUE.
      ENDIF.
      CLEAR ls_entry.
      " a row that no longer fits the entry type is left out - one broken
      " row must not hide the rest of the history
      TRY.
          z2ui5_cl_sql_context=>xml_parse( EXPORTING xml = lr_db->data
                                    IMPORTING any = ls_entry ).
        CATCH z2ui5_cx_sql_error.
          CONTINUE.
      ENDTRY.
      " db_create writes the user and the id into the entry as well - a row
      " whose content claims another user or id was not written by it
      IF ls_entry-uname <> lr_db->uname OR ls_entry-uuid <> lr_db->handle2.
        CONTINUE.
      ENDIF.
      INSERT ls_entry INTO TABLE result.

    ENDLOOP.

  ENDMETHOD.

  METHOD db_delete.

    LOOP AT z2ui5_cl_sql_db=>load_multi_by_handle( uname  = user
                                                    handle = c_handle_history ) REFERENCE INTO DATA(lr_db).

      z2ui5_cl_sql_db=>delete_by_handle( uname        = lr_db->uname
                                          handle       = lr_db->handle
                                          handle2      = lr_db->handle2
                                          check_commit = abap_false ).

    ENDLOOP.
    COMMIT WORK AND WAIT.

  ENDMETHOD.

  METHOD db_create_draft.

    z2ui5_cl_sql_db=>save( uname  = sy-uname
                            handle = c_handle_draft
                            data   = CONV string( val ) ).

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
    DATA(lt_db) = z2ui5_cl_sql_db=>load_multi_by_handle( uname   = sy-uname
                                                          handle  = c_handle_history
                                                          handle2 = val ).
    IF lt_db IS INITIAL.
      RETURN.
    ENDIF.
    DATA(ls_db) = lt_db[ 1 ].
    IF ls_db-uname <> sy-uname OR ls_db-handle <> c_handle_history OR ls_db-handle2 <> val.
      RETURN.
    ENDIF.

    " an entry that no longer fits the entry type reads as not found
    TRY.
        z2ui5_cl_sql_context=>xml_parse( EXPORTING xml = ls_db-data
                                  IMPORTING any = result ).
      CATCH z2ui5_cx_sql_error.
        CLEAR result.
        RETURN.
    ENDTRY.
    " the caller deserializes result_data into objects - only an entry that
    " is the user's own by its content too is handed out (see db_create)
    IF result-uname <> sy-uname OR result-uuid <> val.
      CLEAR result.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
