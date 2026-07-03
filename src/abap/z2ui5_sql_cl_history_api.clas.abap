CLASS z2ui5_sql_cl_history_api DEFINITION
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

    CLASS-METHODS db_create_draft
      IMPORTING
        VALUE(val) TYPE clike.

    CLASS-METHODS db_read_draft
      RETURNING
        VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS z2ui5_sql_cl_history_api IMPLEMENTATION.

  METHOD db_create.

    val-uname = sy-uname.
    z2ui5_cl_util_db=>save( uname   = val-uname
                            handle  = c_handle_history
                            handle2 = val-uuid
                            data    = val ).

  ENDMETHOD.

  METHOD db_read_multi_by_user.

    DATA ls_entry TYPE ty_s_entry.

    LOOP AT z2ui5_cl_util_db=>load_multi_by_handle( uname  = val
                                                    handle = c_handle_history ) REFERENCE INTO DATA(lr_db).

      z2ui5_cl_util=>xml_parse( EXPORTING xml = lr_db->data
                                IMPORTING any = ls_entry ).
      INSERT ls_entry INTO TABLE result.

    ENDLOOP.

  ENDMETHOD.

  METHOD db_delete.

    LOOP AT z2ui5_cl_util_db=>load_multi_by_handle( uname  = user
                                                    handle = c_handle_history ) REFERENCE INTO DATA(lr_db).

      z2ui5_cl_util_db=>delete_by_handle( uname        = lr_db->uname
                                          handle       = lr_db->handle
                                          handle2      = lr_db->handle2
                                          check_commit = abap_false ).

    ENDLOOP.
    COMMIT WORK AND WAIT.

  ENDMETHOD.

  METHOD db_create_draft.

    z2ui5_cl_util_db=>save( uname  = sy-uname
                            handle = c_handle_draft
                            data   = CONV string( val ) ).

  ENDMETHOD.

  METHOD db_read_draft.

    TRY.
        z2ui5_cl_util_db=>load_by_handle( EXPORTING uname  = sy-uname
                                                    handle = c_handle_draft
                                          IMPORTING result = result ).
      CATCH z2ui5_cx_util_error.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD db_read_by_id.

    DATA(lt_db) = z2ui5_cl_util_db=>load_multi_by_handle( handle  = c_handle_history
                                                          handle2 = val ).
    IF lt_db IS INITIAL.
      RETURN.
    ENDIF.

    z2ui5_cl_util=>xml_parse( EXPORTING xml = lt_db[ 1 ]-data
                              IMPORTING any = result ).

  ENDMETHOD.

ENDCLASS.
