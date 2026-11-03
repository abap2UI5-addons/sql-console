interface z2ui5_if_sql_assoc_processor public.

  types t_data_sources type if_dd_sobject_types=>ty_t_sobjnames.

  methods map_association_to_join
            importing
              i_potential_data_sources type z2ui5_if_sql_assoc_processor=>t_data_sources
              i_association type string
            returning
              value(r_val) type string
            raising
              cx_sql_exception.

endinterface.
