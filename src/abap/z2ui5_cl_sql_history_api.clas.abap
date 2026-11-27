CLASS z2ui5_cl_sql_history_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    CONSTANTS c_handle_history TYPE string VALUE `Z2UI5_SQL_CONSOLE_HISTORY` ##NO_TEXT.
    CONSTANTS c_handle_draft   TYPE string VALUE `Z2UI5_SQL_CONSOLE_DRAFT` ##NO_TEXT.
    "! The entries a user's history keeps: db_create deletes the oldest
    "! beyond them
    CONSTANTS c_history_max    TYPE i VALUE 100.

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

    "! The user's history list - without result_data, which db_read_by_id
    "! reads for one entry
    CLASS-METHODS db_read_multi_by_user
      IMPORTING
        val           TYPE clike DEFAULT sy-uname
      RETURNING
        VALUE(result) TYPE ty_t_entry.

    "! One entry of the user's own history, with its result
    "! @parameter val | the entry's id (uuid). Pass it: the default
    "! sy-uname is deprecated - it looks for an entry whose id is the user
    "! name - and will be removed in a later release
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

    "! handle3 of an entry's second document, the one with its result
    CONSTANTS c_handle3_result TYPE string VALUE `RESULT` ##NO_TEXT.

    "! Deletes the user's oldest entries beyond c_history_max; the entry
    "! with the id keep stays
    CLASS-METHODS history_trim
      IMPORTING
        uname TYPE clike
        keep  TYPE clike.

    "! Deletes both documents of an entry
    CLASS-METHODS entry_delete
      IMPORTING
        uname TYPE clike
        uuid  TYPE clike.

ENDCLASS.



CLASS z2ui5_cl_sql_history_api IMPLEMENTATION.

  METHOD db_create.

    val-uname = sy-uname.

    " two documents per entry: the list fields alone (handle3 initial) and
    " the whole entry with its result (handle3 RESULT) - the list reads and
    " parses only the small ones, a result is parsed when it is loaded
    DATA(ls_list) = val.
    CLEAR ls_list-result_data.
    z2ui5_cl_sql_db=>save( uname        = val-uname
                            handle       = c_handle_history
                            handle2      = val-uuid
                            data         = ls_list
                            check_commit = abap_false ).
    z2ui5_cl_sql_db=>save( uname        = val-uname
                            handle       = c_handle_history
                            handle2      = val-uuid
                            handle3      = c_handle3_result
                            data         = val
                            check_commit = abap_false ).

    history_trim( uname = val-uname
                  keep  = val-uuid ).
    COMMIT WORK AND WAIT.

  ENDMETHOD.

  METHOD db_read_multi_by_user.

    DATA ls_entry TYPE ty_s_entry.

    LOOP AT z2ui5_cl_sql_db=>load_multi_by_handle( uname   = val
                                                    handle  = c_handle_history
                                                    handle3 = `` ) REFERENCE INTO DATA(lr_db).

      " only the requested user's own history rows are read, and of each
      " entry the document without the result
      IF lr_db->uname <> val OR lr_db->handle <> c_handle_history OR lr_db->handle3 IS NOT INITIAL.
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
      " an entry written before the result got a document of its own
      " carries it here
      CLEAR ls_entry-result_data.
      INSERT ls_entry INTO TABLE result.

    ENDLOOP.

  ENDMETHOD.

  METHOD db_delete.

    LOOP AT z2ui5_cl_sql_db=>load_multi_by_handle( uname  = user
                                                    handle = c_handle_history ) REFERENCE INTO DATA(lr_db).

      z2ui5_cl_sql_db=>delete_by_handle( uname        = lr_db->uname
                                          handle       = lr_db->handle
                                          handle2      = lr_db->handle2
                                          handle3      = lr_db->handle3
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
                                                          handle2 = val
                                                          handle3 = c_handle3_result ).
    " an entry written before the result got a document of its own has
    " the one document, with the result in it
    IF lt_db IS INITIAL.
      lt_db = z2ui5_cl_sql_db=>load_multi_by_handle( uname   = sy-uname
                                                      handle  = c_handle_history
                                                      handle2 = val
                                                      handle3 = `` ).
    ENDIF.
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

  METHOD history_trim.

    TYPES:
      BEGIN OF ty_s_age,
        timestampl TYPE timestampl,
        uuid       TYPE ty_s_entry-uuid,
      END OF ty_s_age.
    DATA lt_age   TYPE STANDARD TABLE OF ty_s_age WITH EMPTY KEY.
    DATA ls_entry TYPE ty_s_entry.

    " the small list documents only - and those are parsed only once the
    " history has grown beyond its limit
    DATA(lt_db) = z2ui5_cl_sql_db=>load_multi_by_handle( uname   = uname
                                                          handle  = c_handle_history
                                                          handle3 = `` ).
    IF lines( lt_db ) <= c_history_max.
      RETURN.
    ENDIF.

    LOOP AT lt_db REFERENCE INTO DATA(lr_db).
      IF lr_db->handle2 = keep.
        CONTINUE.
      ENDIF.
      " a row that does not parse counts as the oldest - the list leaves it
      " out anyway
      CLEAR ls_entry.
      TRY.
          z2ui5_cl_sql_context=>xml_parse( EXPORTING xml = lr_db->data
                                    IMPORTING any = ls_entry ).
        CATCH z2ui5_cx_sql_error.
          CLEAR ls_entry.
      ENDTRY.
      INSERT VALUE #( timestampl = ls_entry-timestampl
                      uuid       = lr_db->handle2 ) INTO TABLE lt_age.
    ENDLOOP.

    " the kept entry is one of the c_history_max
    SORT lt_age BY timestampl DESCENDING.
    LOOP AT lt_age INTO DATA(ls_age) FROM c_history_max.
      entry_delete( uname = uname
                    uuid  = ls_age-uuid ).
    ENDLOOP.

  ENDMETHOD.

  METHOD entry_delete.

    z2ui5_cl_sql_db=>delete_by_handle( uname        = uname
                                        handle       = c_handle_history
                                        handle2      = uuid
                                        check_commit = abap_false ).
    z2ui5_cl_sql_db=>delete_by_handle( uname        = uname
                                        handle       = c_handle_history
                                        handle2      = uuid
                                        handle3      = c_handle3_result
                                        check_commit = abap_false ).

  ENDMETHOD.

ENDCLASS.
