CLASS z2ui5_cl_sql_app_01 DEFINITION PUBLIC.

  PUBLIC SECTION.

    INTERFACES z2ui5_if_app.

    " the spreadsheet exporter's column list, written as JSON and bound with
    " json = abap_true: the exporter reads lower-case keys, which an ABAP
    " component name never serializes to
    DATA mv_column_config TYPE string.
    " the preview table the nested view binds (through a field symbol)
    DATA mr_preview_tab TYPE REF TO data.

    TYPES:
      BEGIN OF ty_history_out,
        s_db  TYPE z2ui5_cl_sql_history_api=>ty_s_entry,
        time  TYPE string,
        date  TYPE string,
        selkz TYPE abap_bool,
      END OF ty_history_out.

    TYPES:
      BEGIN OF ty_s_preview,
        tab            TYPE REF TO data,
        tab_backup     TYPE REF TO data,
        cont_size      TYPE string,
        title          TYPE string,
        search_field   TYPE string,
        t_filter       TYPE z2ui5_cl_sql_context=>ty_t_filter_multi,
        rtti_data      TYPE string,
        rtti_data_back TYPE string,
      END OF ty_s_preview.

    DATA:
      BEGIN OF ms_draft,
        s_preview         TYPE ty_s_preview,
        sql_input         TYPE string,
        sql_s_command     TYPE z2ui5_cl_sql_context=>ty_s_filter_multi,
        sql_max_rows      TYPE i,
        sql_cont_size     TYPE string,
        history_cont_size TYPE string,
        history_tab       TYPE STANDARD TABLE OF ty_history_out WITH DEFAULT KEY,
        appwidthlimited   TYPE abap_bool,
      END OF ms_draft.

  PROTECTED SECTION.

    DATA:
      BEGIN OF ms_control,
        callback_pop_session_load  TYPE string,
        callback_pop_history_clear TYPE string,
      END OF ms_control.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS z2ui5_view_display.

    METHODS history_db_read.
    METHODS preview_filter_search.
    METHODS preview_filter_range.
    METHODS history_on_clear_pressed.
    METHODS z2ui5_on_callback.
    METHODS z2ui5_on_event.
    METHODS sql_on_run.

    METHODS sql_view_display
      IMPORTING
        view_sql TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS preview_view.
    METHODS history_view
      IMPORTING
        view_history TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS preview_on_filter_clear.
    METHODS z2ui5_on_callback_pop_confirm
      IMPORTING
        io_popup TYPE REF TO z2ui5_cl_popup_to_confirm.
    METHODS history_on_load.
    METHODS history_db_save.
    "! DATE and TIME of a history row, from its timestamp (UTC)
    METHODS history_set_date_time
      CHANGING
        cs_out TYPE ty_history_out.
    METHODS z2ui5_on_init_set_app.
    METHODS preview_on_filter.

    METHODS result_display
      IMPORTING
        fw_table     TYPE string
        fo_result    TYPE REF TO data
        ft_fieldlist TYPE z2ui5_cl_sql_query=>ty_t_fieldlist
        fw_title     TYPE string.

  PRIVATE SECTION.

ENDCLASS.



CLASS z2ui5_cl_sql_app_01 IMPLEMENTATION.


  METHOD history_db_read.
    DATA ls_out TYPE ty_history_out.
    DATA temp1 TYPE z2ui5_cl_sql_history_api=>ty_t_entry.
    DATA temp3 LIKE LINE OF temp1.
    DATA lr_history LIKE REF TO temp3.
      DATA temp2 TYPE z2ui5_cl_sql_app_01=>ty_history_out.

    CLEAR ms_draft-history_tab.


    temp1 = z2ui5_cl_sql_history_api=>db_read_multi_by_user( ).


    LOOP AT temp1 REFERENCE INTO lr_history.

      " the list leaves the result out - assigned and cleared, not
      " CORRESPONDING #( ... EXCEPT ), which has no 7.02 downport
      CLEAR ls_out.
      ls_out-s_db = lr_history->*.
      CLEAR ls_out-s_db-result_data.
      history_set_date_time( CHANGING cs_out = ls_out ).
      INSERT ls_out INTO TABLE ms_draft-history_tab.

    ENDLOOP.

    SORT ms_draft-history_tab BY s_db-timestampl DESCENDING.

    IF ms_draft-history_tab IS INITIAL.

      CLEAR temp2.
      temp2-selkz = abap_true.
      INSERT temp2 INTO TABLE ms_draft-history_tab.
    ENDIF.

  ENDMETHOD.


  METHOD history_db_save.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab_back> TYPE STANDARD TABLE.
    DATA temp3 LIKE LINE OF ms_draft-history_tab.
    DATA lr_hist LIKE REF TO temp3.
      DATA temp4 TYPE z2ui5_cl_sql_app_01=>ty_history_out.
    DATA ls_preview LIKE ms_draft-s_preview.
    DATA temp5 TYPE z2ui5_cl_sql_history_api=>ty_s_entry.
    ASSIGN ms_draft-s_preview-tab->* TO <tab>.


    ASSIGN ms_draft-s_preview-tab_backup->* TO <tab_back>.



    LOOP AT ms_draft-history_tab REFERENCE INTO lr_hist WHERE selkz = abap_true.
      EXIT.
    ENDLOOP.
    IF lr_hist IS NOT BOUND.
      " no row selected - the run becomes the newest row of the list, as
      " history_db_read would show it after a restart

      CLEAR temp4.
      temp4-selkz = abap_true.
      INSERT temp4 INTO ms_draft-history_tab INDEX 1 REFERENCE INTO lr_hist.
    ENDIF.

    ls_preview = ms_draft-s_preview.
    CLEAR ls_preview-tab.
    CLEAR ls_preview-tab_backup.

    ls_preview-rtti_data = z2ui5_cl_sql_context=>xml_srtti_stringify( <tab> ).
    IF <tab_back> IS ASSIGNED.
      ls_preview-rtti_data_back = z2ui5_cl_sql_context=>xml_srtti_stringify( <tab_back> ).
    ENDIF.

    lr_hist->s_db-timestampl = z2ui5_cl_sql_context=>time_get_timestampl( ).
    IF lr_hist->s_db-uuid IS INITIAL.
      lr_hist->s_db-uuid = z2ui5_cl_sql_context=>uuid_get_c32( ).
    ENDIF.

    CLEAR temp5.
    temp5-sql_command = ms_draft-sql_input.
    temp5-tabname = ms_draft-sql_s_command-name.
    temp5-timestampl = lr_hist->s_db-timestampl.
    temp5-uuid = lr_hist->s_db-uuid.
    temp5-counter = lines( <tab> ).
    temp5-result_data = z2ui5_cl_sql_context=>xml_srtti_stringify( ls_preview ).
    z2ui5_cl_sql_history_api=>db_create( temp5 ).

    lr_hist->s_db-sql_command = ms_draft-sql_input.
    lr_hist->s_db-tabname = ms_draft-sql_s_command-name.
    lr_hist->s_db-counter = lines( <tab> ).
    history_set_date_time( CHANGING cs_out = lr_hist->* ).

  ENDMETHOD.


  METHOD history_set_date_time.
    DATA lv_iso TYPE string.
    DATA lv_fraction TYPE string.

    " the list shows {DATE} {TIME}; DATE stayed empty and TIME carried the
    " whole ISO timestamp - split it at the T, without the fraction
    CLEAR: cs_out-date, cs_out-time.
    IF cs_out-s_db-timestampl IS INITIAL.
      RETURN.
    ENDIF.

    lv_iso = |{ cs_out-s_db-timestampl TIMESTAMP = ISO }|.
    SPLIT lv_iso AT `T` INTO cs_out-date cs_out-time.

    SPLIT cs_out-time AT `,` INTO cs_out-time lv_fraction ##NEEDED.

  ENDMETHOD.


  METHOD history_on_clear_pressed.

    IF ms_draft-history_tab IS INITIAL.
      client->message_box_display( `No history entries found. No action needed.` ).
      RETURN.
    ENDIF.
    ms_control-callback_pop_history_clear = client->nav_app_call( z2ui5_cl_popup_to_confirm=>factory( `Delete all history entries from database?` ) ).

  ENDMETHOD.


  METHOD history_on_load.

    DATA ls_arg TYPE z2ui5_cl_sql_app_01=>ty_history_out.
    FIELD-SYMBOLS <temp4> LIKE LINE OF ms_draft-history_tab.
    DATA temp5 LIKE sy-tabix.
    DATA ls_entry TYPE z2ui5_cl_sql_history_api=>ty_s_entry.
    DATA lr_preview TYPE REF TO data.
      FIELD-SYMBOLS <any> TYPE any.
      DATA lr_data TYPE REF TO data.
    temp5 = sy-tabix.
    READ TABLE ms_draft-history_tab WITH KEY selkz = abap_true ASSIGNING <temp4>.
    sy-tabix = temp5.
    IF sy-subrc <> 0.
      ASSERT 1 = 0.
    ENDIF.
    ls_arg = <temp4>.

    ls_entry = z2ui5_cl_sql_history_api=>db_read_by_id( ls_arg-s_db-uuid ).
    ms_draft-sql_input = ls_entry-sql_command.


    CLEAR ms_draft-s_preview-tab.

    IF ls_entry-result_data IS NOT INITIAL.
      lr_preview = z2ui5_cl_sql_context=>xml_srtti_parse( ls_entry-result_data ).


      ASSIGN lr_preview->('title') TO <any>.
      ms_draft-s_preview-title = <any>.
      ASSIGN lr_preview->('search_field') TO <any>.
      ms_draft-s_preview-search_field = <any>.
      ASSIGN lr_preview->('t_filter') TO <any>.
      ms_draft-s_preview-t_filter = <any>.



      ASSIGN lr_preview->('rtti_data') TO <any>.
      lr_data = z2ui5_cl_sql_context=>xml_srtti_parse( <any> ).
      ms_draft-s_preview-tab = z2ui5_cl_sql_context=>conv_copy_ref_data( lr_data ).

      ASSIGN lr_preview->('rtti_data_back') TO <any>.
      lr_data = z2ui5_cl_sql_context=>xml_srtti_parse( <any> ).
      ms_draft-s_preview-tab_backup = z2ui5_cl_sql_context=>conv_copy_ref_data( lr_data ).

    ENDIF.

    client->view_model_update( ).
    preview_view( ).
    client->message_toast_display( `History entry successfully loaded` ).

  ENDMETHOD.


  METHOD history_view.

    view_history->ele( `List`
        )->a( n = `items` v = client->_bind_edit( ms_draft-history_tab )
        )->a( n = `mode` v = `SingleSelectMaster`
        )->a( n = `selectionChange` v = client->_event( val = `HISTORY_LOAD` )
        )->a( n = `sticky` v = `ColumnHeaders,HeaderToolbar`
        )->ele( `headerToolbar`
        )->ele( `OverflowToolbar`
        )->tag( `Title`
        )->a( n = `text` v = `Query History`
        )->tag( `ToolbarSpacer`
        )->tag( `Button`
        )->a( n = `text` v = `New`
        )->a( n = `press` v = client->_event( `HISTORY_CREATE` )
        )->a( n = `icon` v = `sap-icon://create`
        )->tag( `Button`
        )->a( n = `text` v = `Clear`
        )->a( n = `press` v = client->_event( `HISTORY_CLEAR` )
        )->a( n = `icon` v = `sap-icon://delete`
        )->end(
        )->end(
        )->tag( `StandardListItem`
        )->a( n = `title` v = `{S_DB/TABNAME} - {DATE} {TIME}`
        )->a( n = `description` v = `{S_DB/SQL_COMMAND}`
        )->a( n = `info` v = `{S_DB/COUNTER}`
        )->a( n = `selected` v = `{SELKZ}` ).

  ENDMETHOD.


  METHOD preview_filter_range.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    DATA ls_tab LIKE LINE OF ms_draft-s_preview-t_filter.
      DATA lv_clause TYPE string.
    ASSIGN ms_draft-s_preview-tab->* TO <tab>.

    " a column without a range is no filter - NOT IN an empty range is false
    " for every row and would delete them all

    LOOP AT ms_draft-s_preview-t_filter INTO ls_tab WHERE t_range IS NOT INITIAL.


      lv_clause = ls_tab-name && ` not in ls_tab-t_range`.
      DELETE <tab> WHERE (lv_clause).

    ENDLOOP.

  ENDMETHOD.


  METHOD preview_filter_search.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    ASSIGN ms_draft-s_preview-tab->* TO <tab>.

    IF ms_draft-s_preview-search_field IS NOT INITIAL.

      z2ui5_cl_sql_context=>itab_filter_by_val(
        EXPORTING
          val = ms_draft-s_preview-search_field
        CHANGING
          tab = <tab> ).

    ENDIF.

  ENDMETHOD.


  METHOD preview_on_filter.

    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab2> TYPE STANDARD TABLE.
    ASSIGN ms_draft-s_preview-tab->* TO <tab>.

    ASSIGN ms_draft-s_preview-tab_backup->* TO <tab2>.
    <tab> = <tab2>.
    preview_filter_search( ).
    preview_filter_range( ).
    ms_draft-s_preview-title = |Number of Rows: { lines( <tab> ) }|.

    preview_view( ).
    history_db_save( ).

  ENDMETHOD.


  METHOD preview_on_filter_clear.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab2> TYPE STANDARD TABLE.

    CLEAR ms_draft-s_preview-search_field.


    ASSIGN ms_draft-s_preview-tab->* TO <tab>.


    ASSIGN ms_draft-s_preview-tab_backup->* TO <tab2>.
    <tab> = <tab2>.

    ms_draft-s_preview-title = |Number of Rows: { lines( <tab> ) }|.

    preview_view( ).
    client->message_toast_display( `All filters deleted` ).

  ENDMETHOD.


  METHOD preview_view.

    DATA lo_view_nested TYPE REF TO z2ui5_cl_ui5_view_builder.
      FIELD-SYMBOLS <tab> TYPE table.
      DATA tab TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA toolbar TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lt_fields TYPE abap_component_tab.
      DATA lo_columns TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA lv_field LIKE LINE OF lt_fields.
    lo_view_nested = z2ui5_cl_ui5_view_builder=>factory(
                               )->ele( n = `View` ns = `mvc`
                               )->a( n = `xmlns` v = `sap.m`
                               )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
                               )->a( n = `xmlns:table` v = `sap.ui.table`
                               " abap2ui5lint-disable-next-line unused-namespace-declaration -- z2ui5_cl_cci_spreadsheet=>render( ) writes the prefix
                               )->a( n = `xmlns:z2ui5_cci` v = `z2ui5_cci.cc`
                               )->a( n = `displayBlock` v = `true`
                               )->a( n = `height` v = `100%` ).

    IF ms_draft-s_preview-tab IS BOUND.

      mr_preview_tab = ms_draft-s_preview-tab.
      ASSIGN mr_preview_tab->* TO <tab>.


      tab = lo_view_nested->ele( n = `Table` ns = `table`
                      )->a( n = `id` v = `previewTab`
                      )->a( n = `rows` v = client->_bind( <tab> )
                      )->a( n = `editable` b = abap_false
                      )->a( n = `alternateRowColors` b = abap_true
                      )->a( n = `showColumnVisibilityMenu` b = abap_true
                      )->a( n = `enableSelectAll` b = abap_false
                      )->a( n = `selectionBehavior` v = `RowOnly`
                      )->a( n = `visibleRowCountMode` v = `Interactive`
                      )->a( n = `visibleRowCount` v = `7`
                      )->a( n = `selectionMode` v = `None` ).

      toolbar = tab->ele( n = `extension` ns = `table`
                          )->ele( `OverflowToolbar`
                          )->a( n = `width` v = `100%`
                          )->tag( `Title`
                          )->a( n = `text` v = client->_bind( ms_draft-s_preview-title )
                          )->tag( `ToolbarSpacer`
                          )->tag( `Input`
                          )->a( n = `width` v = `30%`
                          )->a( n = `value` v = client->_bind_edit( ms_draft-s_preview-search_field )
                          )->a( n = `description` v = `All Column Search`
                          )->a( n = `submit` v = client->_event( `PREVIEW_SEARCH` )
                          )->tag( `Button`
                          )->a( n = `text` v = `Filter`
                          )->a( n = `press` v = client->_event( `PREVIEW_FILTER` )
                          )->a( n = `icon` v = `sap-icon://filter`
                          )->tag( `Button`
                          )->a( n = `tooltip` v = `Clear Filter`
                          )->a( n = `press` v = client->_event( `PREVIEW_CLEAR_FILTER` )
                          )->a( n = `icon` v = `sap-icon://clear-filter`
                          )->tag( `ToolbarSpacer` ).

      " a preview restored from the history has no column list of its own -
      " json = abap_true needs valid JSON, so an empty list it is
      IF mv_column_config IS INITIAL.
        mv_column_config = `[]`.
      ENDIF.

      " the control's XML element belongs to custom-controls, which delivers
      " the matching JavaScript as a BSP - building the tag here by hand is
      " what let the two drift apart
      z2ui5_cl_cci_spreadsheet=>render(
          view    = toolbar
          tableid = `previewTab`
          icon    = `sap-icon://excel-attachment`
          type    = `Emphasized`
          columns = client->_bind( val  = mv_column_config
                                   json = abap_true ) ).


      lt_fields = z2ui5_cl_sql_context=>rtti_get_t_attri_by_any( <tab> ).


      lo_columns = tab->ele( n = `columns` ns = `table` ).

      LOOP AT lt_fields INTO lv_field.
        lo_columns->ele( n = `Column` ns = `table`
            )->a( n = `width` v = `auto`
            )->a( n = `sortProperty` t = lv_field-name
            )->a( n = `filterProperty` t = lv_field-name
            )->tag( `Text`
            )->a( n = `text` t = lv_field-name
            )->ele( n = `template` ns = `table`
            )->tag( `Label`
            )->a( n = `text` v = `{` && lv_field-name && `}`
            )->a( n = `wrapping` b = abap_true ).
      ENDLOOP.

    ELSE.
      lo_view_nested->tag( `Text`
          )->a( n = `text` v = `Data preview...` ).
    ENDIF.

    client->nest_view_display( val            = lo_view_nested->stringify( )
                               id             = `preview`
                               method_insert  = `addItem`
                               method_destroy = `removeAllItems` ).

  ENDMETHOD.


  METHOD result_display.

    DATA: lo_descr_table TYPE REF TO cl_abap_tabledescr,
          lo_descr_line  TYPE REF TO cl_abap_structdescr,
          lt_comp        TYPE cl_abap_structdescr=>component_table,
          ls_comp        TYPE cl_abap_structdescr=>component.

    FIELD-SYMBOLS <lft_data> TYPE ANY TABLE.
    DATA temp6 TYPE string_table.
    DATA lt_column_json LIKE temp6.
      FIELD-SYMBOLS <temp7> LIKE LINE OF ft_fieldlist.
      DATA temp8 LIKE sy-tabix.
      DATA temp9 LIKE LINE OF lt_column_json.
    DATA lo_new_type TYPE REF TO cl_abap_structdescr.
    DATA lo_new_tab TYPE REF TO cl_abap_tabledescr.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <tab2> TYPE STANDARD TABLE.

    ASSIGN fo_result->* TO <lft_data>.

    lo_descr_table ?=
      cl_abap_typedescr=>describe_by_data_ref( fo_result ).
    lo_descr_line ?= lo_descr_table->get_table_line_type( ).

    lt_comp = lo_descr_line->get_components( ).


    CLEAR temp6.

    lt_column_json = temp6.
    LOOP AT lt_comp INTO ls_comp.



      temp8 = sy-tabix.
      READ TABLE ft_fieldlist INDEX sy-tabix ASSIGNING <temp7>.
      sy-tabix = temp8.
      IF sy-subrc <> 0.
        ASSERT 1 = 0.
      ENDIF.
      ls_comp-name = <temp7>-ref_field.

      MODIFY lt_comp FROM ls_comp USING KEY loop_key.


      temp9 = |\{"label":"{ ls_comp-name }","property":"{ ls_comp-name }","type":"String"\}|.
      APPEND temp9 TO lt_column_json.

    ENDLOOP.
    mv_column_config = |[{ concat_lines_of( table = lt_column_json sep = `,` ) }]|.


    lo_new_type = cl_abap_structdescr=>create( lt_comp ).

    lo_new_tab = cl_abap_tabledescr=>create(
                        p_line_type  = lo_new_type
                        p_table_kind = cl_abap_tabledescr=>tablekind_std
                        p_unique     = abap_false ).


    CREATE DATA ms_draft-s_preview-tab TYPE HANDLE lo_new_tab.
    ASSIGN ms_draft-s_preview-tab->* TO <tab>.
    <tab> = <lft_data>.


    CREATE DATA ms_draft-s_preview-tab_backup TYPE HANDLE lo_new_tab.
    ASSIGN ms_draft-s_preview-tab_backup->* TO <tab2>.
    <tab2> = <tab>.

    preview_view( ).

    ms_draft-s_preview-t_filter = z2ui5_cl_sql_context=>filter_get_multi_by_data( <tab> ).
    ms_draft-s_preview-title = |Number of Rows: { lines( <tab2> ) }|.

    history_db_save( ).
    client->view_model_update( ).

  ENDMETHOD.


  METHOD sql_on_run.
        DATA ls_result TYPE z2ui5_cl_sql_query=>ty_s_result.
        DATA lx_error TYPE REF TO z2ui5_cx_sql_error.

    TRY.

        ls_result = z2ui5_cl_sql_query=>run( query    = ms_draft-sql_input
                                                   max_rows = ms_draft-sql_max_rows ).

      CATCH z2ui5_cx_sql_error INTO lx_error.
        client->message_box_display( text = lx_error->get_text( )
                                     type = `error` ).
        RETURN.
    ENDTRY.

    ms_draft-sql_s_command-name = ls_result-tabname.

    result_display(
        fw_table     = ls_result-from
        fo_result    = ls_result-data
        ft_fieldlist = ls_result-fieldlist
        fw_title     = ls_result-query
    ).

  ENDMETHOD.


  METHOD sql_view_display.

    view_sql->tag( n = `CodeEditor` ns = `editor`
        )->a( n = `type` v = `sql`
        )->a( n = `value` v = client->_bind_edit( ms_draft-sql_input ) ).

  ENDMETHOD.


  METHOD z2ui5_if_app~main.
          DATA temp10 TYPE string_table.
        DATA x TYPE REF TO cx_root.
    TRY.

        me->client = client.

        IF client->check_on_init( ) IS NOT INITIAL.

          client->view_display( z2ui5_cl_ui5_view_builder=>factory(
            )->ele( n = `View` ns = `mvc`
            )->a( n = `xmlns` v = `sap.m`
            )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
            )->a( n = `xmlns:core` v = `sap.ui.core`
            )->a( n = `displayBlock` v = `true`
            )->a( n = `height` v = `100%`
            )->stringify( ) ).
          " the empty view is on screen first; START builds the console in
          " the roundtrip the client timer fires right after it rendered

          CLEAR temp10.
          INSERT `START` INTO TABLE temp10.
          INSERT `0` INTO TABLE temp10.
          client->follow_up_action(
              val   = z2ui5_if_client=>cs_event-start_timer
              t_arg = temp10 ).

          RETURN.
        ENDIF.

        IF client->get( )-check_on_navigated = abap_true.
          z2ui5_on_callback( ).
          RETURN.
        ENDIF.

        z2ui5_on_event( ).


      CATCH cx_root INTO x.
        client->nav_app_call( z2ui5_cl_popup_error=>factory( x ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD z2ui5_on_callback.
        DATA temp12 TYPE REF TO z2ui5_cl_popup_to_confirm.
        DATA lo_popup_confirm LIKE temp12.
        DATA temp13 TYPE REF TO z2ui5_cl_popup_get_ranges.
        DATA lo_popup_range LIKE temp13.

    TRY.

        temp12 ?= client->get_app( client->get( )-s_draft-id_prev_app ).

        lo_popup_confirm = temp12.
        z2ui5_on_callback_pop_confirm( lo_popup_confirm ).
        RETURN.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

    TRY.

        temp13 ?= client->get_app( client->get( )-s_draft-id_prev_app ).

        lo_popup_range = temp13.
        IF lo_popup_range->result( )-check_confirmed = abap_true.
          ms_draft-s_preview-t_filter = lo_popup_range->result( )-t_filter.
          preview_on_filter( ).
        ENDIF.
        RETURN.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

    TRY.
        z2ui5_view_display( ).
        RETURN.
      CATCH cx_root ##NO_HANDLER.
    ENDTRY.

  ENDMETHOD.


  METHOD z2ui5_on_callback_pop_confirm.
          DATA lv_id TYPE string.

    CASE io_popup->z2ui5_if_app~id_app.

      WHEN ms_control-callback_pop_session_load.

        IF io_popup->result( ) IS NOT INITIAL.

          lv_id = z2ui5_cl_sql_history_api=>db_read_draft( ).
          client->nav_app_leave( client->get_app( lv_id ) ).
        ELSE.
          z2ui5_on_init_set_app( ).
        ENDIF.

      WHEN ms_control-callback_pop_history_clear.

        " Cancel keeps the history
        IF io_popup->result( ) = abap_false.
          RETURN.
        ENDIF.

        CLEAR ms_draft-history_tab.
        client->view_model_update( ).
        z2ui5_cl_sql_history_api=>db_delete( ).
        client->message_toast_display( `All entries successfully deleted from database` ).

    ENDCASE.

  ENDMETHOD.


  METHOD z2ui5_on_event.
        DATA temp14 LIKE LINE OF ms_draft-history_tab.
        DATA lr_hist LIKE REF TO temp14.
        DATA temp15 TYPE z2ui5_cl_sql_app_01=>ty_history_out.

    z2ui5_cl_sql_history_api=>db_create_draft( client->get( )-s_draft-id ).

    CASE client->get( )-event.
      WHEN `START`.
        z2ui5_on_init_set_app( ).

      WHEN `PREVIEW_FILTER`.
        client->nav_app_call( z2ui5_cl_popup_get_ranges=>factory( ms_draft-s_preview-t_filter ) ).

      WHEN `PREVIEW_CLEAR_FILTER`.
        preview_on_filter_clear( ).

      WHEN `PREVIEW_SEARCH`.
        preview_on_filter( ).

      WHEN `RUN`.
        sql_on_run( ).

      WHEN `HISTORY_CLEAR`.
        history_on_clear_pressed( ).

      WHEN `HISTORY_CREATE`.
        " the new entry is the selected one - history_db_save writes into the
        " first selected row, which would still be the old entry otherwise


        LOOP AT ms_draft-history_tab REFERENCE INTO lr_hist WHERE selkz = abap_true.
          lr_hist->selkz = abap_false.
        ENDLOOP.

        CLEAR temp15.
        temp15-selkz = abap_true.
        INSERT temp15 INTO TABLE ms_draft-history_tab.
        client->view_model_update( ).

      WHEN `HISTORY_LOAD`.
        history_on_load( ).

      WHEN `BACK`.
        client->nav_app_leave( client->get_app( client->get( )-s_draft-id_prev_app_stack ) ).

    ENDCASE.

  ENDMETHOD.


  METHOD z2ui5_on_init_set_app.

    ms_draft-sql_input = `Select * from T100`.
    ms_draft-history_cont_size = `30%`.
    ms_draft-sql_cont_size = `auto`.
    ms_draft-s_preview-cont_size = `auto`.
    ms_draft-sql_max_rows = 500.
    ms_draft-appwidthlimited = abap_true.
    z2ui5_view_display( ).

    history_db_read( ).

  ENDMETHOD.


  METHOD z2ui5_view_display.

    DATA view TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA page TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA cont_main TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA cont_sub TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA view_sql TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA view_history TYPE REF TO z2ui5_cl_ui5_view_builder.
    view = z2ui5_cl_ui5_view_builder=>factory(
                     )->ele( n = `View` ns = `mvc`
                     )->a( n = `xmlns` v = `sap.m`
                     )->a( n = `xmlns:mvc` v = `sap.ui.core.mvc`
                     )->a( n = `xmlns:editor` v = `sap.ui.codeeditor`
                     )->a( n = `xmlns:layout` v = `sap.ui.layout`
                     )->a( n = `displayBlock` v = `true`
                     )->a( n = `height` v = `100%` ).

    page = view->ele( `Shell`
                     )->a( n = `appWidthLimited` v = client->_bind_edit( ms_draft-appwidthlimited )
                     )->ele( `Page`
                     )->a( n = `title` v = `ABAP SQL Console`
                     )->a( n = `navButtonPress` v = client->_event( `BACK` )
                     )->a( n = `showNavButton` b = abap_true
                     )->ele( `headerContent`
                     )->ele( `OverflowToolbar`
                     )->tag( `Label`
                     )->a( n = `text` v = `Max Rows`
                     )->tag( `Input`
                     )->a( n = `width` v = `15%`
                     )->a( n = `value` v = client->_bind_edit( ms_draft-sql_max_rows )
                     )->tag( `Button`
                     )->a( n = `text` v = `Run`
                     )->a( n = `press` v = client->_event( `RUN` )
                     )->a( n = `type` v = `Emphasized`
                     )->tag( `ToolbarSpacer`
                     )->tag( `Label`
                     )->a( n = `text` v = `Shell`
                     )->tag( `Switch`
                     )->a( n = `state` v = client->_bind_edit( ms_draft-appwidthlimited )
                     )->tag( `Link`
                     )->a( n = `text` v = `Project on GitHub`
                     )->a( n = `target` v = `_blank`
                     )->a( n = `href` v = `https://github.com/abap2UI5-addons/sql-console`
                     )->end(
                     )->end( ).


    cont_main = page->ele( n = `ResponsiveSplitter` ns = `layout`
                          )->ele( n = `PaneContainer` ns = `layout`
                          )->a( n = `orientation` v = `Vertical` ).


    cont_sub = cont_main->ele( n = `PaneContainer` ns = `layout`
                         )->a( n = `orientation` v = `Horizontal` ).


    view_sql = cont_sub->ele( n = `SplitPane` ns = `layout`
                         )->a( n = `requiredParentWidth` v = `600`
                         )->ele( n = `layoutData` ns = `layout`
                         )->ele( n = `SplitterLayoutData` ns = `layout`
                         )->a( n = `size` v = client->_bind_edit( ms_draft-sql_cont_size )
                         )->end(
                         )->end( ).

    sql_view_display( view_sql ).


    view_history = cont_sub->ele( n = `SplitPane` ns = `layout`
                             )->a( n = `requiredParentWidth` v = `400`
                             )->ele( n = `layoutData` ns = `layout`
                             )->ele( n = `SplitterLayoutData` ns = `layout`
                             )->a( n = `size` v = client->_bind_edit( ms_draft-history_cont_size )
                             )->end(
                             )->end( ).

    history_view( view_history ).

    cont_main->ele( n = `SplitPane` ns = `layout`
        )->a( n = `requiredParentWidth` v = `400`
        )->ele( n = `layoutData` ns = `layout`
        )->ele( n = `SplitterLayoutData` ns = `layout`
        )->a( n = `size` v = client->_bind_edit( ms_draft-s_preview-cont_size )
        )->end(
        )->end(
        )->ele( `VBox`
        )->a( n = `id` v = `preview` ).

    preview_view( ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.
ENDCLASS.
